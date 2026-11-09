import 'package:flutter/material.dart';

import 'widgets/slide_to_trash_sheet.dart';

import '../../../core/shared_widgets/app_ui.dart';

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

    final result = await DatabaseBackupService.importDatabase();
    if (!mounted) {
      // Pantalla cerrada a mitad: no se deja un backup sin versión a medias
      if (result.status == BackupImportStatus.unknownVersion) {
        await DatabaseBackupService.rollbackPendingImport();
      }
      return;
    }
    setState(() => _isImporting = false);
    final l10n = context.l10n;

    switch (result.status) {
      case BackupImportStatus.restored:
        _showRestartDialog();
      case BackupImportStatus.failed:
        AppAlerts.showWarning(context, l10n.restoreFailed);
      case BackupImportStatus.versionMismatch:
        await _showVersionDialog(
          l10n.versionMismatchTitle,
          l10n.backupVersionMismatch(
            result.backupVersion ?? '?',
            result.appVersion ?? '?',
          ),
        );
      case BackupImportStatus.unknownVersion:
        // Backup sin versión (anterior a 1.14.1): se deja elegir
        final restore = await _showVersionDialog(
          l10n.backupVersionUnknownTitle,
          l10n.backupVersionUnknown(result.appVersion ?? '?'),
          confirmLabel: l10n.backupRestoreAnyway,
        );
        if (restore) {
          await DatabaseBackupService.confirmPendingImport();
          if (mounted) _showRestartDialog();
        } else {
          await DatabaseBackupService.rollbackPendingImport();
          if (mounted) AppAlerts.showInfo(context, l10n.backupNotRestored);
        }
    }
  }

  /// Aviso de versión. Con [confirmLabel] pregunta (true = confirmar);
  /// sin él es solo informativo.
  Future<bool> _showVersionDialog(
    String title,
    String message, {
    String? confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.system_update_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          if (confirmLabel != null)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, confirmLabel != null),
            child: Text(confirmLabel ?? context.l10n.understood),
          ),
        ],
      ),
    );
    return result == true;
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

    // Tercer paso: arrastrar la base de datos a la papelera
    final thrownAway = await showSlideToTrashSheet(context);
    if (!thrownAway || !mounted) return;

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
    final busy = _isExporting || _isImporting || _isDeleting;
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
          padding: EdgeInsets.all(AppSpacing.page(context)),
          children: [
            _ActionTile(
              icon: Icons.sync_alt,
              title: context.l10n.syncByQrTitle,
              subtitle: context.l10n.syncByQrDescription,
              highlighted: true,
              onTap: busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SyncScreen()),
                    ),
            ),
            SectionLabel(
              context.l10n.backupSectionTitle,
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
            ),
            _ActionTile(
              icon: Icons.download_rounded,
              title: context.l10n.exportBackupTitle,
              subtitle: context.l10n.exportBackupDescription,
              loading: _isExporting,
              onTap: busy ? null : _handleExport,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionTile(
              icon: Icons.upload_rounded,
              title: context.l10n.restoreBackupTitle,
              subtitle: context.l10n.restoreBackupDescription,
              loading: _isImporting,
              onTap: busy ? null : _handleImport,
            ),
            const SizedBox(height: AppSpacing.xl),
            _ActionTile(
              icon: Icons.delete_forever_outlined,
              title: context.l10n.databaseDeleteTitle,
              subtitle: context.l10n.databaseDeleteDescription,
              loading: _isDeleting,
              danger: true,
              onTap: busy ? null : _confirmDatabaseDeletion,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de acción: icono (o progreso) · título y descripción · flecha.
/// [danger] la pinta en rojo; [highlighted] destaca la acción principal.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
    this.danger = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;
  final bool danger;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = danger ? colors.error : colors.primary;

    return AppCard(
      onTap: onTap,
      borderColor: danger
          ? colors.error.withValues(alpha: 0.35)
          : highlighted
          ? colors.primary.withValues(alpha: 0.35)
          : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: accent,
                    ),
                  )
                : IconBadge(icon, color: accent, size: highlighted ? 24 : 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: highlighted ? 16 : 15,
                    color: danger ? colors.error : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
