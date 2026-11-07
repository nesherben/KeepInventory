import 'dart:math';

/// Contenido del QR de sincronización.
///
/// Formato v2 (URI):
/// `keepinventory://sync?v=2&port=8080&token=XYZ&hosts=192.168.1.5,10.0.0.1`
/// más, en modo punto de acceso, `&ssid=...&pw=...&sec=wpa2|wpa3|open`.
///
/// También acepta el QR antiguo (`http://ip:8080/download-db`) para
/// recibir datos de una versión anterior de la app.
class SyncInvite {
  const SyncInvite({
    required this.port,
    required this.hosts,
    this.token,
    this.ssid,
    this.password,
    this.security = 'wpa2',
    this.legacyUrl,
  });

  static const scheme = 'keepinventory';
  static const version = '2';

  final int port;

  /// Direcciones IPv4 candidatas del emisor, por orden de preferencia.
  final List<String> hosts;

  /// Código de un solo uso que el servidor exige para entregar los datos.
  final String? token;

  /// Red del punto de acceso del emisor (null = misma Wi‑Fi).
  final String? ssid;
  final String? password;
  final String security;

  /// URL completa del formato antiguo, si el QR era de una versión previa.
  final String? legacyUrl;

  bool get usesHotspot => ssid != null && ssid!.isNotEmpty;

  /// Genera un token aleatorio seguro (sin caracteres ambiguos).
  static String newToken({int length = 24}) {
    const chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// URL de descarga contra un host concreto.
  Uri downloadUri(String host, {String? requestId}) => legacyUrl != null
      ? Uri.parse(legacyUrl!)
      : _uri(host, '/download-db', {'id': ?requestId});

  /// Pide al emisor permiso para copiar los datos.
  Uri requestUri(String host, String requestId, String deviceName) =>
      _uri(host, '/request', {'id': requestId, 'device': deviceName});

  /// Consulta si el emisor ya aprobó/rechazó la solicitud.
  Uri statusUri(String host, String requestId) =>
      _uri(host, '/status', {'id': requestId});

  Uri _uri(String host, String path, Map<String, String> extra) => Uri(
    scheme: 'http',
    host: host,
    port: port,
    path: path,
    queryParameters: {'token': ?token, ...extra},
  );

  /// URL de comprobación rápida ("¿estás ahí?").
  Uri pingUri(String host) => Uri(
    scheme: 'http',
    host: host,
    port: port,
    path: '/ping',
    queryParameters: {'token': ?token},
  );

  String toQrData() => Uri(
    scheme: scheme,
    host: 'sync',
    queryParameters: {
      'v': version,
      'port': '$port',
      'token': ?token,
      'hosts': hosts.join(','),
      if (usesHotspot) ...{'ssid': ssid!, 'pw': ?password, 'sec': security},
    },
  ).toString();

  /// Interpreta el texto de un QR. Null si no es de KeepInventory.
  static SyncInvite? parse(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    if (uri == null) return null;

    // Formato antiguo: http://ip:puerto/download-db
    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.path.endsWith('/download-db') &&
        uri.host.isNotEmpty) {
      return SyncInvite(
        port: uri.hasPort ? uri.port : 80,
        hosts: [uri.host],
        legacyUrl: text,
      );
    }

    if (uri.scheme != scheme || uri.host != 'sync') return null;
    final q = uri.queryParameters;
    final port = int.tryParse(q['port'] ?? '');
    final hosts = (q['hosts'] ?? '')
        .split(',')
        .map((h) => h.trim())
        .where((h) => h.isNotEmpty)
        .toList();
    if (port == null || port <= 0 || port > 65535) return null;

    final ssid = q['ssid'];
    return SyncInvite(
      port: port,
      hosts: hosts,
      token: q['token'],
      ssid: (ssid == null || ssid.isEmpty) ? null : ssid,
      password: q['pw'],
      security: q['sec'] ?? 'wpa2',
    );
  }
}
