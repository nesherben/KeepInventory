import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restart_app/restart_app.dart';

import '../../../core/services/hotspot_service.dart';
import '../../../core/services/sync_approval.dart';
import '../../../core/services/sync_invite.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_ui.dart';
import '../../../core/theme/app_colors.dart';

/// Sincronización entre dos móviles mediante QR.
///
/// - "Emitir sin Wi‑Fi": el emisor crea un punto de acceso temporal y el QR
///   lleva la red, la contraseña y un código de un solo uso.
/// - "Emitir por la misma red": como antes, ambos en el mismo Wi‑Fi.
/// - "Recibir": escanea el QR, se conecta (si hace falta) y descarga.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double? _startX;
  double? _startY;

  /// Invitación activa mientras este móvil emite.
  SyncInvite? _invite;

  /// Aprobación de solicitudes: nadie copia los datos sin permiso del emisor.
  SyncApprovalGate? _gate;
  bool _isStarting = false;
  bool _isReceiving = false;
  String _statusMessage = '';
  double _progressValue = 0.0;

  bool get _isServerRunning => _invite != null;

  @override
  void dispose() {
    _gate?.dispose();
    SyncService.stopServer();
    HotspotService.stop();
    HotspotService.disconnect();
    super.dispose();
  }

  // --------------------------------------------------------------- Emisor

  Future<void> _startHosting({required bool useHotspot}) async {
    final l10n = context.l10n;
    setState(() {
      _isStarting = true;
      _statusMessage = useHotspot ? l10n.syncHotspotStarting : '';
    });

    HotspotInfo? hotspot;
    if (useHotspot) {
      try {
        hotspot = await HotspotService.start();
        // La interfaz del punto de acceso tarda un instante en tener IP
        await Future.delayed(const Duration(milliseconds: 1500));
      } on HotspotException catch (e) {
        if (!mounted) return;
        setState(() => _isStarting = false);
        _showHotspotError(e.error);
        return;
      }
    }

    final token = SyncInvite.newToken();
    _gate?.dispose();
    final gate = _gate = SyncApprovalGate(onRequest: _onSyncRequest);
    final hosts = await SyncService.startServer(
      l10n,
      (error) {
        if (mounted) AppAlerts.showError(context, error);
      },
      token: token,
      gate: gate,
    );

    if (!mounted) return;
    if (hosts == null) {
      if (useHotspot) await HotspotService.stop();
      setState(() => _isStarting = false);
      return;
    }

    setState(() {
      _isStarting = false;
      _invite = SyncInvite(
        port: SyncService.port,
        hosts: hosts,
        token: token,
        ssid: hotspot?.ssid,
        password: hotspot?.password,
        security: hotspot?.security ?? 'wpa2',
      );
    });
    AppAlerts.showSuccess(context, l10n.syncServerReady);
  }

  Future<void> _stopHosting() async {
    _gate?.dispose();
    _gate = null;
    await SyncService.stopServer();
    await HotspotService.stop();
    if (!mounted) return;
    setState(() => _invite = null);
    AppAlerts.showInfo(context, context.l10n.syncServerStopped);
  }

  void _showHotspotError(HotspotError error) {
    final l10n = context.l10n;
    final message = switch (error) {
      HotspotError.permissionDenied => l10n.syncHotspotPermissionDenied,
      HotspotError.locationOff => l10n.syncHotspotLocationOff,
      HotspotError.incompatibleMode => l10n.syncHotspotIncompatible,
      HotspotError.unsupported => l10n.syncHotspotUnsupported,
      HotspotError.unavailable || HotspotError.failed => l10n.syncHotspotFailed,
    };

    if (error == HotspotError.locationOff) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.location_off_outlined),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                HotspotService.openLocationSettings();
              },
              child: Text(context.l10n.syncOpenSettings),
            ),
          ],
        ),
      );
    } else {
      AppAlerts.showError(
        context,
        message,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Un receptor pide copiar los datos: el emisor decide en pantalla.
  Future<void> _onSyncRequest(SyncRequest request) async {
    if (!mounted) return;
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ApprovalDialog(request: request),
    );
    final gate = _gate;
    if (gate == null || !mounted) return;
    if (allowed == true) {
      gate.approve(request.id);
      AppAlerts.showSuccess(
        context,
        context.l10n.syncRequestApproved(request.device),
      );
    } else {
      gate.deny(request.id);
      AppAlerts.showInfo(context, context.l10n.syncRequestDenied);
    }
  }

  // ------------------------------------------------------------- Receptor

  void _openScanner() {
    var scannerActive = true; // Evita varios escaneos en un segundo

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (scannerContext) => Scaffold(
          appBar: AppBar(title: Text(scannerContext.l10n.scannerTitle)),
          body: MobileScanner(
            onDetect: (capture) {
              if (!scannerActive) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw == null) continue;
                final invite = SyncInvite.parse(raw);
                scannerActive = false;
                Navigator.pop(scannerContext);
                if (invite == null) {
                  AppAlerts.showError(context, context.l10n.syncInvalidQr);
                } else {
                  _performImport(invite);
                }
                break;
              }
            },
          ),
        ),
      ),
    );
  }

  void _updateProgress(String status, double progress) {
    if (!mounted) return;
    setState(() {
      _statusMessage = status;
      _progressValue = progress;
    });
  }

  Future<void> _performImport(SyncInvite invite) async {
    final l10n = context.l10n;
    setState(() {
      _isReceiving = true;
      _statusMessage = l10n.syncVerifyNetwork;
      _progressValue = 0.0;
    });

    final preferredHosts = <String>[];
    var success = false;
    try {
      if (invite.usesHotspot) {
        final connected = await _joinSenderNetwork(invite);
        if (connected == null) {
          if (mounted) setState(() => _isReceiving = false);
          return;
        }
        if (connected.isNotEmpty) preferredHosts.add(connected);
      }

      if (!mounted) return;
      success = await SyncService.importDatabase(
        invite,
        l10n,
        _updateProgress,
        preferredHosts: preferredHosts,
        deviceName: await HotspotService.deviceName(),
      );
    } finally {
      // Siempre volvemos a la red normal del móvil
      await HotspotService.disconnect();
    }

    if (!mounted) return;
    setState(() => _isReceiving = false);
    if (success) {
      _showRestartDialog();
    } else {
      AppAlerts.showError(context, l10n.syncErrorPrefix(_statusMessage));
    }
  }

  /// Conecta a la red del emisor. Devuelve la puerta de enlace ('' si no se
  /// conoce) o null si el usuario no pudo/quiso conectarse.
  Future<String?> _joinSenderNetwork(SyncInvite invite) async {
    final l10n = context.l10n;
    if (!await HotspotService.canConnectAutomatically()) {
      // Android 9 o anterior: conexión manual guiada
      final done = await _showManualConnectDialog(invite);
      return done ? '' : null;
    }

    _updateProgress(l10n.syncConnectingToSender, -1);
    try {
      final gateway = await HotspotService.connect(
        ssid: invite.ssid!,
        password: invite.password,
        security: invite.security,
      );
      return gateway ?? '';
    } on HotspotException {
      if (mounted) AppAlerts.showError(context, l10n.syncConnectFailed);
      return null;
    }
  }

  Future<bool> _showManualConnectDialog(SyncInvite invite) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.wifi),
        title: Text(context.l10n.syncManualConnectTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.syncManualConnectBody),
            const SizedBox(height: AppSpacing.md),
            _NetworkCredentials(invite: invite),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.syncManualConnectDone),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(context.l10n.syncSuccessTitle)),
          ],
        ),
        content: Text(context.l10n.syncSuccessMessage),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: Text(context.l10n.restartNow),
            onPressed: () => Restart.restartApp(),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Listener(
      onPointerDown: (event) {
        _startX = event.position.dx;
        _startY = event.position.dy;
      },
      onPointerMove: (event) {
        if (_startX == null || _startY == null) return;
        final dx = event.position.dx - _startX!;
        final dy = event.position.dy - _startY!;
        if (dx > 50 && dy.abs() < 30) {
          _startX = null;
          _startY = null;
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      onPointerUp: (_) {
        _startX = null;
        _startY = null;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: Text(context.l10n.syncTitle)),
        drawer: const AppDrawer(),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync_alt,
                      size: 44,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.syncLocalTitle,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.syncLocalDescription,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_isReceiving || _isStarting)
                    ..._buildProgress(colors)
                  else if (!_isServerRunning)
                    ..._buildIdleActions()
                  else
                    ..._buildBroadcasting(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProgress(ColorScheme colors) => [
    Text(
      _statusMessage,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: AppSpacing.lg),
    LinearProgressIndicator(
      value: _progressValue >= 0 && !_isStarting ? _progressValue : null,
      minHeight: 10,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      backgroundColor: colors.surfaceContainerHighest,
    ),
    const SizedBox(height: AppSpacing.sm),
    Text(
      _progressValue > 0 && !_isStarting
          ? context.percent(_progressValue * 100)
          : '',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ];

  List<Widget> _buildIdleActions() => [
    SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.wifi_tethering),
        label: Text(context.l10n.syncEmitHotspot),
        onPressed: () => _startHosting(useHotspot: true),
      ),
    ),
    const SizedBox(height: AppSpacing.xs),
    Text(
      context.l10n.syncEmitHotspotHint,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: AppSpacing.lg),
    SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(context.l10n.syncReceiveData),
        onPressed: _openScanner,
      ),
    ),
    const SizedBox(height: AppSpacing.sm),
    TextButton.icon(
      icon: const Icon(Icons.wifi, size: 18),
      label: Text(context.l10n.syncEmitSameWifi),
      onPressed: () => _startHosting(useHotspot: false),
    ),
  ];

  List<Widget> _buildBroadcasting(ColorScheme colors) {
    final invite = _invite!;
    return [
      Text(
        context.l10n.syncScanFromReceiver,
        style: const TextStyle(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),
      // Fondo blanco siempre (también en modo oscuro) para escanear bien
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: QrImageView(
          data: invite.toQrData(),
          version: QrVersions.auto,
          size: 220.0,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      if (invite.usesHotspot)
        _NetworkCredentials(invite: invite)
      else
        Text(
          context.l10n.syncActiveIp(invite.hosts.first),
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
      const SizedBox(height: AppSpacing.xl),
      FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: colors.errorContainer,
          foregroundColor: colors.onErrorContainer,
        ),
        icon: const Icon(Icons.stop),
        label: Text(context.l10n.syncStopBroadcast),
        onPressed: _stopHosting,
      ),
    ];
  }
}

/// Nombre y contraseña de la red del emisor (por si hay que conectar a mano).
class _NetworkCredentials extends StatelessWidget {
  const _NetworkCredentials({required this.invite});

  final SyncInvite invite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 13, color: colors.onSurface);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  context.l10n.syncHotspotNetwork(invite.ssid ?? ''),
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
                if ((invite.password ?? '').isNotEmpty)
                  SelectableText(
                    context.l10n.syncHotspotPassword(invite.password!),
                    style: style,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo del emisor: quién pide los datos y el código de verificación.
class _ApprovalDialog extends StatelessWidget {
  const _ApprovalDialog({required this.request});

  final SyncRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.phonelink_lock, color: colors.primary, size: 32),
      title: Text(context.l10n.syncApprovalTitle, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.syncApprovalBody(request.device),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              request.code,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.syncApprovalCodeHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          if (request.address != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              request.address!,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.syncApprovalDeny),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: Text(context.l10n.syncApprovalAllow),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
