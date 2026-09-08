import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/services/database_backup_service.dart';
import 'sync_screen.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double? _startX;
  double? _startY;

  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    AppAlerts.showInfo(context, 'Selecciona dónde guardar la copia...');

    final success = await DatabaseBackupService.exportDatabase();

    if (mounted) {
      setState(() => _isExporting = false);
      if (success) {
        AppAlerts.showSuccess(
          context,
          '✨ ¡Copia de seguridad guardada con éxito!',
        );
      } else {
        AppAlerts.showWarning(
          context,
          'Exportación cancelada u ocurrió un error.',
        );
      }
    }
  }

  Future<void> _handleImport() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    AppAlerts.showWarning(
      context,
      'Busca el archivo de respaldo en tu dispositivo...',
    );

    final success = await DatabaseBackupService.importDatabase();

    if (mounted) {
      setState(() => _isImporting = false);
      if (success) {
        _showRestartDialog();
      } else {
        AppAlerts.showWarning(
          context,
          'Restauración cancelada u ocurrió un error.',
        );
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Base de Datos Restaurada'),
        content: const Text(
          'La base de datos se ha actualizado correctamente. Es necesario reiniciar la aplicación para aplicar los cambios de forma segura.',
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
        appBar: AppBar(title: const Text('Gestión de Datos')),
        drawer: const AppDrawer(),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sync_alt,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                title: const Text(
                  'Sincronización por QR (Ferias)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Clona la base de datos completa con otro dispositivo cercano vía Wi-Fi o Hotspot.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SyncScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                'COPIAS DE SEGURIDAD EN ARCHIVO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.blue),
                title: const Text('Exportar copia de seguridad'),
                subtitle: const Text(
                  'Guarda un archivo de respaldo de tu base de datos.',
                ),
                onTap: _isExporting || _isImporting ? null : _handleExport,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: _isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.upload_rounded, color: Colors.orange),
                title: const Text('Restaurar copia de seguridad'),
                subtitle: const Text(
                  'Carga un archivo de respaldo previo para recuperar datos.',
                ),
                onTap: _isExporting || _isImporting ? null : _handleImport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
