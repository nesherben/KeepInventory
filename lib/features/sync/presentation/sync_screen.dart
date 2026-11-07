import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/shared_widgets/app_ui.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:restart_app/restart_app.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/services/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double? _startX;
  double? _startY;

  String? _serverUrl;
  bool _isServerRunning = false;
  bool _isReceiving = false;
  String _statusMessage = '';
  double _progressValue = 0.0;

  Future<void> _startHosting() async {
    final l10n = context.l10n;
    final url = await SyncService.startServer(l10n, (error) {
      if (context.mounted) AppAlerts.showError(context, error);
    });

    if (!mounted) return;
    if (url != null) {
      setState(() {
        _serverUrl = url;
        _isServerRunning = true;
      });
      AppAlerts.showSuccess(context, l10n.syncServerReady);
    }
  }

  Future<void> _stopHosting() async {
    await SyncService.stopServer();
    if (!mounted) return;
    setState(() {
      _serverUrl = null;
      _isServerRunning = false;
    });
    AppAlerts.showInfo(context, context.l10n.syncServerStopped);
  }

  @override
  void dispose() {
    SyncService.stopServer();
    super.dispose();
  }

  void _openScanner() {
    bool isScannerActive =
        true; // 💡 CANDADO: Evita escaneos múltiples en 1 segundo

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(context.l10n.scannerTitle)),
          body: MobileScanner(
            onDetect: (capture) {
              // Si el candado está cerrado, ignoramos todo lo que lea la cámara
              if (!isScannerActive) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? url = barcode.rawValue;
                if (url != null && url.startsWith('http')) {
                  // 💡 Cerramos el candado inmediatamente tras la primera lectura buena
                  isScannerActive = false;
                  Navigator.pop(context);
                  _performImport(url);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _performImport(String url) async {
    setState(() {
      _isReceiving = true;
      _statusMessage = context.l10n.syncVerifyNetwork;
      _progressValue = 0.0;
    });

    final success = await SyncService.importDatabase(url, context.l10n, (
      status,
      progress,
    ) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
          _progressValue = progress;
        });
      }
    });

    if (mounted) {
      setState(() => _isReceiving = false);

      if (success) {
        _showRestartDialog();
      } else {
        AppAlerts.showError(
          context,
          context.l10n.syncErrorPrefix(_statusMessage),
        );
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text(context.l10n.syncSuccessTitle)),
          ],
        ),
        content: Text(context.l10n.syncSuccessMessage),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: Text(context.l10n.restartNow),
            onPressed: () {
              Restart.restartApp();
            },
          ),
        ],
      ),
    );
  }

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
                  if (_isReceiving) ...[
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LinearProgressIndicator(
                      value: _progressValue >= 0 ? _progressValue : null,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _progressValue >= 0
                          ? context.percent(_progressValue * 100)
                          : '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ] else if (!_isServerRunning) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.upload),
                        label: Text(context.l10n.syncEmitData),
                        onPressed: _startHosting,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(context.l10n.syncReceiveData),
                        onPressed: _openScanner,
                      ),
                    ),
                  ] else ...[
                    Text(
                      context.l10n.syncScanFromReceiver,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Fondo blanco siempre (también en modo oscuro) para que
                    // el QR se escanee bien
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: QrImageView(
                        data: _serverUrl!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.l10n.syncActiveIp(_serverUrl!.split('/')[2]),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
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
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
