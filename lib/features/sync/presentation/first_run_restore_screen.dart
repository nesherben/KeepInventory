import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/services/app_preferences.dart';
import '../../../core/services/backup_validator.dart';
import '../../../core/services/database_backup_service.dart';
import '../../../core/services/drive_backup_service.dart';
import '../../../core/services/local_backup_service.dart';
import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/shared_widgets/app_ui.dart';
import '../../../core/utils/backup_formatters.dart';
import 'backup_restore_flow.dart';

/// Primer arranque con la base de datos vacía: ofrece recuperar los datos de
/// una copia (del móvil, de Drive o de un archivo) antes del tutorial.
class FirstRunRestoreScreen extends StatefulWidget {
  const FirstRunRestoreScreen({super.key});

  @override
  State<FirstRunRestoreScreen> createState() => _FirstRunRestoreScreenState();
}

class _FirstRunRestoreScreenState extends State<FirstRunRestoreScreen> {
  bool _loading = true;
  bool _busy = false;
  bool _hasAccess = false;
  LocalBackupFile? _latest;
  BackupInfo? _latestInfo;

  @override
  void initState() {
    super.initState();
    _search();
  }

  /// Busca la copia más reciente que se pueda restaurar.
  Future<void> _search() async {
    var access = false;
    LocalBackupFile? latest;
    BackupInfo? latestInfo;
    try {
      access = await LocalBackupService.hasFilesAccess();
      for (final backup in await LocalBackupService.listBackups()) {
        final info = await BackupValidator.inspect(backup.file);
        if (info.isValid && !info.isEmpty) {
          latest = backup;
          latestInfo = info;
          break;
        }
      }
    } catch (e) {
      // Si no se puede buscar, se sigue con las demás opciones
      debugPrint('No se pudieron buscar copias: $e');
    }
    if (!mounted) return;
    setState(() {
      _hasAccess = access;
      _latest = latest;
      _latestInfo = latestInfo;
      _loading = false;
    });
  }

  Future<void> _requestAccess() async {
    setState(() => _busy = true);
    await LocalBackupService.requestFilesAccess();
    await _search();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restoreLatest() async {
    final latest = _latest;
    if (latest == null || _busy) return;
    setState(() => _busy = true);
    await confirmAndRestore(context, latest.file, date: latest.modified);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restoreFromDrive() async {
    if (_busy) return;
    setState(() => _busy = true);
    final service = DriveBackupService();
    try {
      if (AppPreferences.driveEmail == null) {
        await DriveBackupService.signIn();
      }
      final info = await service.findBackup();
      if (!mounted) return;
      if (info == null) {
        AppAlerts.showInfo(context, context.l10n.driveNoBackups);
      } else {
        final file = await runWithBlockingProgress(
          context,
          title: context.l10n.backupOperationDownloading,
          task: (reportProgress) =>
              service.download(info, onProgress: reportProgress),
        );
        if (!mounted) return;
        await confirmAndRestore(
          context,
          file,
          date: info.modified,
          deleteAfter: true,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        final failure = e is DriveException ? e.failure : DriveFailure.failed;
        switch (failure) {
          case DriveFailure.cancelled:
            AppAlerts.showInfo(context, l10n.driveSignInCancelled);
          case DriveFailure.offline:
            AppAlerts.showWarning(context, l10n.driveErrorOffline);
          case DriveFailure.notConfigured:
          case DriveFailure.failed:
            AppAlerts.showError(context, l10n.driveErrorGeneric);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseFile() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await DatabaseBackupService.importDatabase();
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = context.l10n;
    switch (result.status) {
      case BackupImportStatus.restored:
      case BackupImportStatus.unknownVersion:
        // En una instalación nueva no hay datos que perder: se acepta
        await DatabaseBackupService.confirmPendingImport();
        await AppPreferences.markTutorialSeen();
        if (mounted) await showRestoredDialog(context);
      case BackupImportStatus.versionMismatch:
        AppAlerts.showError(context, l10n.backupRestoreNewer);
      case BackupImportStatus.failed:
        AppAlerts.showWarning(context, l10n.restoreFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final latest = _latest;
    final info = _latestInfo;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.page(context)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: IconBadge(Icons.restore, size: 56)),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.firstRunTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.firstRunBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (latest != null && info != null) ...[
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              children: [
                                const IconBadge(Icons.history),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.firstRunLatestCopy,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${formatBackupDate(context, latest.modified)}'
                                        ' · ${l10n.backupSummary(info.products, info.sales)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _busy ? null : _restoreLatest,
                              child: Text(l10n.firstRunRestore),
                            ),
                          ),
                        ] else if (!_hasAccess) ...[
                          Text(
                            l10n.firstRunPermissionHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _busy ? null : _requestAccess,
                              child: Text(l10n.firstRunSearchLocal),
                            ),
                          ),
                        ] else
                          Text(
                            l10n.firstRunNoCopies,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        if (DriveBackupService.isConfigured) ...[
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _restoreFromDrive,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: Text(l10n.firstRunFromDrive),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _chooseFile,
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(l10n.firstRunChooseFile),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          // Siempre disponible: nunca se queda atascado
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/tutorial',
                          ),
                          child: Text(l10n.firstRunStartFresh),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
