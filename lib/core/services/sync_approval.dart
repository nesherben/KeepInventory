import 'dart:async';

/// Estado de una solicitud de copia de datos.
enum SyncRequestStatus { pending, approved, denied, unknown }

/// Solicitud de un receptor que quiere copiar los datos.
class SyncRequest {
  SyncRequest({required this.id, required this.device, this.address});

  final String id;
  final String device;
  final String? address;

  /// Código de 4 cifras que ambos móviles muestran para comprobar que se
  /// aprueba el dispositivo correcto.
  String get code => verificationCode(id);
}

/// Código de verificación derivado del id de la solicitud (FNV-1a).
String verificationCode(String id) {
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return (hash % 10000).toString().padLeft(4, '0');
}

/// "Portero" del servidor de sincronización: el emisor debe aprobar cada
/// solicitud antes de que se entreguen los datos.
///
/// - Una solicitud sin respuesta se rechaza sola tras [pendingTimeout].
/// - Una aprobación permite [maxDownloads] descargas (reintentos si se corta
///   la red) durante [approvalValidity]; después caduca.
class SyncApprovalGate {
  SyncApprovalGate({
    required this.onRequest,
    this.pendingTimeout = const Duration(minutes: 2),
    this.approvalValidity = const Duration(minutes: 10),
    this.maxDownloads = 3,
    this.maxPending = 5,
  });

  /// Avisa a la interfaz del emisor de una nueva solicitud.
  final void Function(SyncRequest request) onRequest;
  final Duration pendingTimeout;
  final Duration approvalValidity;
  final int maxDownloads;

  /// Límite de solicitudes pendientes a la vez (evita saturar al emisor).
  final int maxPending;

  final Map<String, _Entry> _entries = {};

  /// Registra una solicitud (idempotente para el mismo id).
  /// Devuelve false si se rechaza por exceso de solicitudes pendientes.
  bool register(SyncRequest request) {
    if (_entries.containsKey(request.id)) return true;
    final pending = _entries.values
        .where((e) => e.status == SyncRequestStatus.pending)
        .length;
    if (pending >= maxPending) return false;

    final entry = _Entry(request);
    entry.timer = Timer(pendingTimeout, () {
      if (entry.status == SyncRequestStatus.pending) {
        entry.status = SyncRequestStatus.denied;
      }
    });
    _entries[request.id] = entry;
    onRequest(request);
    return true;
  }

  SyncRequestStatus status(String? id) =>
      _entries[id]?.status ?? SyncRequestStatus.unknown;

  /// Solo tiene efecto si la solicitud sigue pendiente.
  void approve(String id) => _resolve(id, approved: true);

  void deny(String id) => _resolve(id, approved: false);

  void _resolve(String id, {required bool approved}) {
    final entry = _entries[id];
    if (entry == null || entry.status != SyncRequestStatus.pending) return;
    entry.timer?.cancel();
    if (approved) {
      entry.status = SyncRequestStatus.approved;
      entry.timer = Timer(approvalValidity, () {
        entry.status = SyncRequestStatus.denied;
      });
    } else {
      entry.status = SyncRequestStatus.denied;
    }
  }

  /// Consume una descarga. False si no está aprobada o ya se agotó.
  bool consumeDownload(String? id) {
    final entry = _entries[id];
    if (entry == null || entry.status != SyncRequestStatus.approved) {
      return false;
    }
    if (entry.downloads >= maxDownloads) return false;
    entry.downloads++;
    return true;
  }

  void dispose() {
    for (final e in _entries.values) {
      e.timer?.cancel();
    }
    _entries.clear();
  }
}

class _Entry {
  _Entry(this.request);

  final SyncRequest request;
  SyncRequestStatus status = SyncRequestStatus.pending;
  int downloads = 0;
  Timer? timer;
}
