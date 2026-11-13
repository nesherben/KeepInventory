import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'widgets/slide_to_trash_sheet.dart';

import '../../../core/shared_widgets/app_ui.dart';

import 'package:restart_app/restart_app.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/services/backup_coordinator.dart';
import '../../../core/services/database_backup_service.dart';
import '../../../core/services/local_backup_service.dart';
import 'backup_restore_flow.dart';
import 'sync_screen.dart';
import 'widgets/settings_group.dart';
import 'widgets/auto_backup_section.dart';
import 'widgets/drive_backup_section.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double? _startX;
  double? _startY;

  bool _isImporting = false;
  bool _isDeleting = false;

  /// "Hacer una copia antes" de borrar: copia en la carpeta de siempre.
  Future<void> _copyBeforeDelete() async {
    final result = await LocalBackupService.createBackup(force: true);
    await BackupCoordinator.refresh();
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result.status) {
      case LocalBackupStatus.created:
        AppAlerts.showSuccess(context, l10n.backupNowDone);
      case LocalBackupStatus.empty:
      case LocalBackupStatus.unchanged:
        AppAlerts.showInfo(context, l10n.backupNowEmpty);
      case LocalBackupStatus.failed:
        AppAlerts.showError(context, l10n.backupNowFailed);
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
        // Copia de otra versión (anterior): se actualiza al abrirla
        if (result.backupVersion != result.appVersion &&
            result.backupVersion != null) {
          AppAlerts.showInfo(
            context,
            l10n.backupRestoreOlderVersion(result.backupVersion!),
          );
        }
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
    if (_isImporting || _isDeleting) return;

    final firstConfirmation = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.l10n.databaseDeleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.databaseDeleteWarning),
            const SizedBox(height: 8),
            Text(
              context.l10n.databaseDeleteKeepsBackups,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // Antes de borrar todo, la opción de guardar una copia
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'export'),
              icon: const Icon(Icons.save_alt, size: 18),
              label: Text(context.l10n.databaseExportFirst),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: Text(context.l10n.databaseDeleteContinue),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (firstConfirmation == 'export') {
      // "Hacer una copia antes": se copia y no se borra nada
      await _copyBeforeDelete();
      return;
    }
    if (firstConfirmation != 'continue') return;

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

  void _showRestartDialog() => showRestoredDialog(context);

  @override
  Widget build(BuildContext context) {
    final busy = _isImporting || _isDeleting;
    final width = MediaQuery.sizeOf(context).width;
    final page = AppSpacing.page(context);
    // Tablet: dos columnas (lo prioritario a la izquierda) y como mucho
    // 1100 px de ancho; móvil: una columna
    final twoColumns = width >= 840;
    final side = math.max(page, (width - (twoColumns ? 1100 : 720)) / 2);
    final bottom = page + MediaQuery.paddingOf(context).bottom;

    // Lo más usado en ferias: pasar los datos a otro móvil con un QR
    final syncSection = [
      DataSectionLabel(context.l10n.dataSyncSection, first: true),
      _SyncCard(
        onTap: busy
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncScreen()),
              ),
      ),
    ];
    final backupSection = AutoBackupSection(
      enabled: !busy,
      onPickFile: _handleImport,
    );
    final dangerSection = [
      DataSectionLabel(context.l10n.dataDangerSection),
      SettingsGroup(
        borderColor: Theme.of(context).colorScheme.error
            .withValues(alpha: 0.35),
        children: [
          SettingsRow(
            icon: Icons.delete_forever_outlined,
            title: context.l10n.databaseDeleteTitle,
            subtitle: context.l10n.databaseDeleteDescription,
            loading: _isDeleting,
            danger: true,
            onTap: busy ? null : _confirmDatabaseDeletion,
          ),
        ],
      ),
    ];

    final Widget body;
    if (twoColumns) {
      body = SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(side, page, side, bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...syncSection, backupSection],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DriveBackupSection(enabled: !busy, firstInColumn: true),
                  ...dangerSection,
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      body = ListView(
        padding: EdgeInsets.fromLTRB(side, page, side, bottom),
        children: [
          ...syncSection,
          backupSection,
          DriveBackupSection(enabled: !busy),
          ...dangerSection,
        ],
      );
    }

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
        body: body,
      ),
    );
  }
}

/// Tarjeta destacada de la sincronización por QR: lo más usado en ferias.
class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      borderColor: colors.primary.withValues(alpha: 0.4),
      color: Color.alphaBlend(
        colors.primary.withValues(alpha: 0.06),
        Theme.of(context).cardColor,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const IconBadge(Icons.qr_code_2, size: 28),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.syncByQrTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.syncByQrDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right, color: colors.primary),
        ],
      ),
    );
  }
}
