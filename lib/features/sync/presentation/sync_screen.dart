import 'package:flutter/material.dart';
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

  Future<void> _startHosting() async {
    final url = await SyncService.startServer((error) {
      AppAlerts.showError(context, error);
    });

    if (url != null) {
      setState(() {
        _serverUrl = url;
        _isServerRunning = true;
      });
      AppAlerts.showSuccess(
        context,
        '📡 Servidor listo. Muestra el QR al otro dispositivo.',
      );
    }
  }

  Future<void> _stopHosting() async {
    await SyncService.stopServer();
    setState(() {
      _serverUrl = null;
      _isServerRunning = false;
    });
    AppAlerts.showInfo(context, 'Servidor de sincronización cerrado.');
  }

  @override
  void dispose() {
    SyncService.stopServer();
    super.dispose();
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Escanear QR de Sincronización')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? url = barcode.rawValue;
                if (url != null && url.startsWith('http')) {
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
      _statusMessage = 'Iniciando descarga...';
    });

    final success = await SyncService.importDatabase(url, (status) {
      setState(() => _statusMessage = status);
    });

    setState(() => _isReceiving = false);

    if (success) {
      if (mounted) {
        _showRestartDialog();
      }
    } else {
      if (mounted) {
        AppAlerts.showError(context, '❌ Falló la importación de datos.');
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Base de Datos Sincronizada'),
        content: const Text(
          'La base de datos se ha clonado correctamente desde el otro dispositivo. Es necesario reiniciar la aplicación para aplicar los cambios de forma segura.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Restart.restartApp();
            },
            child: const Text('Reiniciar ahora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(title: const Text('Sincronización de Dispositivos')),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sync_alt, size: 64, color: Colors.teal),
                const SizedBox(height: 16),
                const Text(
                  'Sincronización Local (Wi-Fi / Hotspot)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Conecta ambos dispositivos a la misma red Wi-Fi o activa un Hotspot en uno de ellos para clonar el inventario al instante.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (_isReceiving) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ] else if (!_isServerRunning) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                      ),
                      icon: const Icon(Icons.upload),
                      label: const Text('📤 Emitir Datos (Crear QR)'),
                      onPressed: _startHosting,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('📥 Recibir Datos (Escanear QR)'),
                      onPressed: _openScanner,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Escanea este código desde el otro dispositivo:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: QrImageView(
                      data: _serverUrl!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text('Detener Servidor'),
                    onPressed: _stopHosting,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
