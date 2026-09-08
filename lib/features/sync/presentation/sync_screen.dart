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

  // 💡 Variables nuevas para la barra de progreso de descarga
  bool _isReceiving = false;
  String _statusMessage = '';
  double _progressValue = 0.0;

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
        '📡 Servidor listo. Muestra el QR al dispositivo receptor.',
      );
    }
  }

  Future<void> _stopHosting() async {
    await SyncService.stopServer();
    setState(() {
      _serverUrl = null;
      _isServerRunning = false;
    });
    AppAlerts.showInfo(context, 'Servidor de emisión detenido.');
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
                  Navigator.pop(context); // Cierra la cámara
                  _performImport(url); // 💡 Lanza la descarga
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
      _statusMessage = 'Conectando con el emisor...';
      _progressValue = 0.0;
    });

    // 💡 Ahora esperamos status y progress desde el SyncService
    final success = await SyncService.importDatabase(url, (status, progress) {
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
        // 💡 Salta el modal obligatorio de reinicio
        _showRestartDialog();
      } else {
        AppAlerts.showError(context, '❌ Error: $_statusMessage');
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a tocar el botón
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('¡Sincronización Exitosa!')),
          ],
        ),
        content: const Text(
          'La base de datos se ha clonado correctamente desde el otro dispositivo. Es necesario reiniciar la aplicación para cargar el nuevo inventario.',
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reiniciar ahora'),
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
                  'Activa un Hotspot en el emisor o conecta ambos a la misma red Wi-Fi para clonar el inventario al instante.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 💡 ESTADO 1: DESCARGANDO (BARRA DE PROGRESO)
                if (_isReceiving) ...[
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progressValue >= 0 ? _progressValue : null,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _progressValue >= 0
                        ? '${(_progressValue * 100).toStringAsFixed(0)}%'
                        : 'Calculando peso...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 💡 ESTADO 2: MENÚ PRINCIPAL (BOTONES)
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

                  // 💡 ESTADO 3: EMITIENDO SEÑAL (QR EN PANTALLA)
                ] else ...[
                  const Text(
                    'Escanea este código desde el receptor:',
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
                  const SizedBox(height: 12),
                  // Muestra la IP para ayudar a depurar si el Hotspot falla
                  Text(
                    'IP Activa: ${_serverUrl!.split('/')[2]}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text('Detener Emisión'),
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
