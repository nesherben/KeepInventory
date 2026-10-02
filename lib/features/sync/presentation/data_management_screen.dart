import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/database/database_helper.dart';
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
  bool _isDeleting = false;

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    AppAlerts.showInfo(context, context.l10n.exportPrompt);

    final success = await DatabaseBackupService.exportDatabase();

    if (mounted) {
      setState(() => _isExporting = false);
      if (success) {
        AppAlerts.showSuccess(context, context.l10n.backupSaved);
      } else {
        AppAlerts.showWarning(context, context.l10n.exportFailed);
      }
    }
  }

  Future<void> _handleImport() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    AppAlerts.showWarning(context, context.l10n.restorePrompt);

    final success = await DatabaseBackupService.importDatabase();

    if (mounted) {
      setState(() => _isImporting = false);
      if (success) {
        _showRestartDialog();
      } else {
        AppAlerts.showWarning(context, context.l10n.restoreFailed);
      }
    }
  }

  Future<void> _confirmDatabaseDeletion() async {
    if (_isExporting || _isImporting || _isDeleting) return;

    final firstConfirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.l10n.databaseDeleteTitle),
        content: Text(context.l10n.databaseDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.databaseDeleteContinue),
          ),
        ],
      ),
    );

    if (firstConfirmation != true || !mounted) return;

    final finalConfirmation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_forever,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.l10n.databaseDeleteFinalTitle),
        content: Text(context.l10n.databaseDeleteFinalWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.databaseDeleteConfirm),
          ),
        ],
      ),
    );

    if (finalConfirmation != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await DatabaseHelper.instance.deleteDatabaseFile();
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showDatabaseDeletedDialog();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppAlerts.showError(context, context.l10n.databaseDeleteFailure);
    }
  }

  void _showDatabaseDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseDeletedTitle),
        content: Text(context.l10n.databaseDeletedMessage),
        actions: [
          ElevatedButton(
            onPressed: Restart.restartApp,
            child: Text(context.l10n.restartNow),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseRestoredTitle),
        content: Text(context.l10n.databaseRestoredMessage),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Restart.restartApp();
            },
            child: Text(context.l10n.restartNow),
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
        appBar: AppBar(title: Text(context.l10n.dataManagementTitle)),
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
                title: Text(
                  context.l10n.syncByQrTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  context.l10n.syncByQrDescription,
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

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                context.l10n.backupSectionTitle,
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
                title: Text(context.l10n.exportBackupTitle),
                subtitle: Text(context.l10n.exportBackupDescription),
                onTap: _isExporting || _isImporting || _isDeleting
                    ? null
                    : _handleExport,
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
                title: Text(context.l10n.restoreBackupTitle),
                subtitle: Text(context.l10n.restoreBackupDescription),
                onTap: _isExporting || _isImporting || _isDeleting
                    ? null
                    : _handleImport,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error
                      .withValues(alpha: 0.35),
                ),
              ),
              child: ListTile(
                leading: _isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                title: Text(
                  context.l10n.databaseDeleteTitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: Text(context.l10n.databaseDeleteDescription),
                onTap: _isExporting || _isImporting || _isDeleting
                    ? null
                    : _confirmDatabaseDeletion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
