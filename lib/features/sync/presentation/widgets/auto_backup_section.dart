import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/backup_coordinator.dart';
import '../../../../core/services/backup_scheduler.dart';
import '../../../../core/services/backup_validator.dart';
import '../../../../core/services/drive_backup_service.dart';
import '../../../../core/services/local_backup_service.dart';
import '../../../../core/shared_widgets/app_alerts.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/backup_formatters.dart';
import '../backup_permission_flow.dart';
import '../backup_restore_flow.dart';
import 'settings_group.dart';

/// Estado y acciones de copias locales, junto con la selección de restauración.
class AutoBackupSection extends StatefulWidget {
  const AutoBackupSection({
    super.key,
    this.enabled = true,
    this.onPickFile,
    this.showStatusCard = true,
    this.showLocalBackups = true,
  });

  /// Se desactivan las acciones mientras otra operación de datos está en curso.
  final bool enabled;

  /// Restaurar un archivo elegido a mano (selector del sistema).
  final Future<void> Function()? onPickFile;

  /// Permite colocar la tarjeta de estado en una columna distinta.
  final bool showStatusCard;

  /// Permite colocar las acciones locales en una columna distinta.
  final bool showLocalBackups;

  @override
  State<AutoBackupSection> createState() => _AutoBackupSectionState();
}

class _AutoBackupSectionState extends State<AutoBackupSection>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool? _hasPermission;
  bool _unsaved = false;
  List<LocalBackupFile> _backups = const [];
  int _refreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackupCoordinator.revision.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    BackupCoordinator.revision.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de Ajustes puede haberse concedido el permiso
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final generation = ++_refreshGeneration;
    try {
      final permission = await LocalBackupService.hasFilesAccess();
      final unsaved = await LocalBackupService.hasUnsavedChanges();
      final backups = await LocalBackupService.listBackups();
      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        _hasPermission = permission;
        _unsaved = unsaved;
        _backups = backups;
      });
    } catch (e) {
      if (generation == _refreshGeneration) {
        debugPrint('No se pudo leer el estado de las copias: $e');
      }
    }
  }

  Future<void> _toggle(bool enable) async {
    if (_busy) return;
    if (!enable) {
      await AppPreferences.setAutoBackupEnabled(false);
      await BackupScheduler.cancel();
      if (mounted) setState(() {});
      return;
    }
    final result = await BackupPermissionFlow.ensure(context);
    if (!mounted) return;
    if (result == BackupPermissionResult.declined) {
      await _refresh();
      return;
    }
    await AppPreferences.setAutoBackupEnabled(true);
    await BackupScheduler.schedule();
    await _backupNow(quiet: true);
  }

  Future<void> _backupNow({
    bool quiet = false,
    bool includeDrive = false,
  }) async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await LocalBackupService.createBackup(force: !quiet);
    if (!mounted) return;
    var driveUploaded = false;
    DriveException? driveError;
    final driveNotConnected =
        includeDrive &&
        (!DriveBackupService.isConfigured || AppPreferences.driveEmail == null);
    if (result.status == LocalBackupStatus.created &&
        includeDrive &&
        !driveNotConnected) {
      try {
        await runWithBlockingProgress(
          context,
          title: l10n.backupOperationUploading,
          task: (reportProgress) =>
              DriveBackupService().upload(onProgress: reportProgress),
        );
        driveUploaded = true;
      } on DriveException catch (error) {
        driveError = error;
      } catch (error) {
        debugPrint('No se pudo subir la copia a Drive: $error');
        driveError = const DriveException(DriveFailure.failed);
      }
    }
    await BackupCoordinator.refresh();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result.status) {
      case LocalBackupStatus.created:
        if (quiet) return;
        if (!includeDrive) {
          AppAlerts.showSuccess(context, l10n.backupNowDone);
        } else if (driveUploaded) {
          AppAlerts.showSuccess(context, l10n.backupLocalAndDriveDone);
        } else if (driveNotConnected) {
          AppAlerts.showWarning(context, l10n.backupLocalOnlyNotConnected);
        } else if (driveError?.failure == DriveFailure.offline) {
          AppAlerts.showWarning(context, l10n.backupLocalOnlyOffline);
        } else {
          AppAlerts.showWarning(context, l10n.backupLocalDriveFailed);
        }
      case LocalBackupStatus.unchanged:
        if (!quiet) AppAlerts.showInfo(context, l10n.backupNowUnchanged);
      case LocalBackupStatus.empty:
        if (!quiet) AppAlerts.showInfo(context, l10n.backupNowEmpty);
      case LocalBackupStatus.failed:
        AppAlerts.showError(context, l10n.backupNowFailed);
    }
  }

  Future<void> _completeSteps() async {
    final result = await BackupPermissionFlow.ensure(context);
    if (!mounted) return;
    if (result != BackupPermissionResult.declined &&
        !AppPreferences.autoBackupEnabled) {
      await AppPreferences.setAutoBackupEnabled(true);
      await BackupScheduler.schedule();
    }
    await _refresh();
  }

  /// Hoja "Restaurar copia": copias del móvil, Drive y otro archivo, todo en
  /// un mismo sitio.
  Future<void> _openRestoreSheet() async {
    final choice = await showModalBottomSheet<_RestoreChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _RestoreSheet(
        backups: _backups,
        showDrive:
            DriveBackupService.isConfigured &&
            AppPreferences.driveEmail != null,
        showFile: widget.onPickFile != null,
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _LocalChoice(:final backup):
        await confirmAndRestore(context, backup.file, date: backup.modified);
      case _DriveChoice():
        await restoreFromDrive(context);
      case _FileChoice():
        await widget.onPickFile?.call();
    }
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = AppPreferences.autoBackupEnabled;
    final needsPermissionSteps =
        enabled &&
        _hasPermission == false &&
        !AppPreferences.backupRiskAccepted;
    final failures = AppPreferences.backupFailures;
    final canAct = widget.enabled && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showStatusCard) ...[
          DataSectionLabel(l10n.dataBackupSection),
          _StatusCard(
            unsaved: _unsaved,
            busy: _busy,
            onBackup: canAct ? () => _backupNow(includeDrive: true) : null,
          ),
        ],
        if (widget.showLocalBackups) ...[
          DataSectionLabel(l10n.backupAutoSectionTitle),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.schedule,
                title: l10n.backupAutoTitle,
                subtitle: l10n.backupAutoSubtitleShort,
                trailing: Switch(
                  value: enabled,
                  onChanged: canAct ? _toggle : null,
                ),
                onTap: canAct ? () => _toggle(!enabled) : null,
              ),
              if (needsPermissionSteps)
                SettingsRow(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.warning,
                  subtitleColor: AppColors.warning,
                  title: l10n.backupPermissionDeniedTitle,
                  subtitle: l10n.backupStepsWarning,
                  trailing: TextButton(
                    onPressed: canAct ? _completeSteps : null,
                    child: Text(l10n.backupCompleteSteps),
                  ),
                ),
              if (failures >= 2)
                SettingsRow(
                  icon: Icons.error_outline,
                  iconColor: AppColors.warning,
                  title: l10n.backupFailuresWarning(failures),
                ),
            ],
          ),
          DataSectionLabel(l10n.backupRestoreTitle),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.restore,
                title: l10n.backupRestoreChooseAction,
                subtitle: l10n.backupRestoreSources,
                onTap: canAct ? _openRestoreSheet : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Estado de las copias con las fechas locales y de Drive.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.unsaved,
    required this.busy,
    required this.onBackup,
  });

  final bool unsaved;
  final bool busy;
  final VoidCallback? onBackup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final lastLocal = AppPreferences.lastLocalBackupAt;
    final lastDrive = AppPreferences.lastDriveBackupAt;

    final (
      IconData icon,
      Color accent,
      String title,
      String body,
    ) = lastLocal == null
        ? (
            Icons.shield_outlined,
            AppColors.warning,
            l10n.backupStatusNoneTitle,
            l10n.backupStatusNoneBody,
          )
        : unsaved
        ? (
            Icons.sync_problem_outlined,
            AppColors.warning,
            l10n.backupStatusPendingTitle,
            l10n.backupStatusPendingBody,
          )
        : (
            Icons.verified_user_outlined,
            AppColors.success,
            l10n.backupStatusSafeTitle,
            l10n.backupStatusSafeBody,
          );

    String when(int? at) => at == null
        ? l10n.backupStatusNever
        : formatBackupDate(context, DateTime.fromMillisecondsSinceEpoch(at));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon, color: accent, size: 26),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _LastCopy(
                  icon: Icons.smartphone,
                  label: l10n.backupStatusPhone,
                  value: when(lastLocal),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _LastCopy(
                  icon: Icons.cloud_outlined,
                  label: l10n.backupStatusDrive,
                  value: when(lastDrive),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onBackup,
              icon: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.backupNowTitle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Última copia en un sitio (móvil o Drive): etiqueta pequeña y fecha.
class _LastCopy extends StatelessWidget {
  const _LastCopy({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Qué restaurar, elegido en la hoja "Restaurar copia".
sealed class _RestoreChoice {
  const _RestoreChoice();
}

class _LocalChoice extends _RestoreChoice {
  const _LocalChoice(this.backup);

  final LocalBackupFile backup;
}

class _DriveChoice extends _RestoreChoice {
  const _DriveChoice();
}

class _FileChoice extends _RestoreChoice {
  const _FileChoice();
}

/// Hoja "Restaurar copia": las copias del móvil (cada una con fecha, tamaño,
/// resumen y botón de compartir), la de Drive y "Elegir otro archivo…".
class _RestoreSheet extends StatelessWidget {
  const _RestoreSheet({
    required this.backups,
    required this.showDrive,
    required this.showFile,
  });

  final List<LocalBackupFile> backups;
  final bool showDrive;
  final bool showFile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.backupRestoreTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  SectionLabel(
                    l10n.backupLocalListTitle,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  ),
                  if (backups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text(
                        l10n.backupNoCopies,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    )
                  else
                    for (final backup in backups) _BackupTile(backup: backup),
                  if (showDrive || showFile) const Divider(),
                  if (showDrive)
                    ListTile(
                      leading: Icon(
                        Icons.cloud_download_outlined,
                        color: colors.primary,
                      ),
                      title: Text(l10n.backupRestoreFromDrive),
                      subtitle: Text(l10n.backupRestoreFromDriveHint),
                      onTap: () => Navigator.pop(context, const _DriveChoice()),
                    ),
                  if (showFile)
                    ListTile(
                      leading: Icon(
                        Icons.folder_open_outlined,
                        color: colors.primary,
                      ),
                      title: Text(l10n.backupRestoreChooseFile),
                      subtitle: Text(l10n.backupRestoreChooseFileHint),
                      onTap: () => Navigator.pop(context, const _FileChoice()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({required this.backup});

  final LocalBackupFile backup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<BackupInfo>(
      future: BackupValidator.inspect(backup.file),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final summary = info == null
            ? '…'
            : info.isValid
            ? l10n.backupSummary(info.products, info.sales)
            : l10n.backupRestoreInvalid;
        return ListTile(
          leading: Icon(
            backup.beforeRestore ? Icons.history : Icons.backup_outlined,
            color: colors.primary,
          ),
          title: Text(
            '${formatBackupDate(context, backup.modified)}'
            ' · ${formatBackupSize(context, backup.sizeBytes)}',
          ),
          subtitle: Text(
            backup.beforeRestore
                ? '${l10n.backupBeforeRestoreLabel} · $summary'
                : summary,
          ),
          // Mandar la copia por correo, Telegram… (sustituye a "Exportar")
          trailing: IconButton(
            tooltip: l10n.backupShare,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(backup.file.path)]),
            ),
          ),
          enabled: info?.isValid ?? false,
          onTap: () => Navigator.pop(context, _LocalChoice(backup)),
        );
      },
    );
  }
}
