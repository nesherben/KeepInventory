import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/backup_coordinator.dart';
import '../../../../core/services/local_backup_service.dart';
import '../../../../core/shared_widgets/app_alerts.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/utils/backup_formatters.dart';
import '../../../sync/presentation/backup_permission_flow.dart';

/// Aviso en el dashboard: cambios sin copiar (con la última copia de hace más
/// de un día) o copia automática que falla varios días seguidos.
class BackupReminderBanner extends StatefulWidget {
  const BackupReminderBanner({super.key});

  @override
  State<BackupReminderBanner> createState() => _BackupReminderBannerState();
}

class _BackupReminderBannerState extends State<BackupReminderBanner> {
  bool _busy = false;

  Future<void> _backupNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final permission = await BackupPermissionFlow.ensure(context);
    if (!mounted) return;
    if (permission == BackupPermissionResult.declined) {
      setState(() => _busy = false);
      return;
    }
    final result = await LocalBackupService.createBackup(force: true);
    await BackupCoordinator.refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.status == LocalBackupStatus.created) {
      AppAlerts.showSuccess(context, context.l10n.backupNowDone);
    } else if (result.status == LocalBackupStatus.failed) {
      AppAlerts.showError(context, context.l10n.backupNowFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: BackupCoordinator.failures,
      builder: (context, failures, _) => ValueListenableBuilder<bool>(
        valueListenable: BackupCoordinator.reminderNeeded,
        builder: (context, needed, _) {
          final l10n = context.l10n;
          final colors = Theme.of(context).colorScheme;
          if (failures >= 2 && AppPreferences.autoBackupEnabled) {
            return _Banner(
              color: colors.error,
              icon: Icons.error_outline,
              title: l10n.backupFailuresWarning(failures),
              body: null,
              action: FilledButton.tonal(
                onPressed: () =>
                    Navigator.pushNamed(context, '/data-management'),
                child: Text(l10n.backupOpenSettings),
              ),
            );
          }
          if (!needed) return const SizedBox.shrink();
          final lastAt = AppPreferences.lastLocalBackupAt;
          return _Banner(
            color: colors.tertiary,
            icon: Icons.backup_outlined,
            title: l10n.backupReminderTitle,
            body: lastAt == null
                ? l10n.backupReminderNever
                : l10n.backupReminderLast(
                    formatBackupDate(
                      context,
                      DateTime.fromMillisecondsSinceEpoch(lastAt),
                    ),
                  ),
            action: FilledButton.tonal(
              onPressed: _busy ? null : _backupNow,
              child: Text(l10n.backupNowTitle),
            ),
            onClose: BackupCoordinator.dismissReminder,
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    this.onClose,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? body;
  final Widget action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        borderColor: color.withValues(alpha: 0.35),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (body != null)
                    Text(
                      body!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(alignment: Alignment.centerLeft, child: action),
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: context.l10n.backupReminderLater,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}
