import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/backup_coordinator.dart';
import '../../../../core/services/local_backup_service.dart';
import '../../../../core/shared_widgets/app_alerts.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
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

  /// Botón compacto de la franja.
  Widget _action(String label, VoidCallback? onPressed) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: BackupCoordinator.failures,
      builder: (context, failures, _) => ValueListenableBuilder<bool>(
        valueListenable: BackupCoordinator.reminderNeeded,
        builder: (context, needed, _) {
          final l10n = context.l10n;
          if (failures >= 2 && AppPreferences.autoBackupEnabled) {
            return _Banner(
              color: AppColors.warning,
              icon: Icons.error_outline,
              title: l10n.backupFailuresWarning(failures),
              action: _action(
                l10n.backupOpenSettings,
                () => Navigator.pushNamed(context, '/data-management'),
              ),
            );
          }
          if (!needed) return const SizedBox.shrink();
          return _Banner(
            color: AppColors.warning,
            icon: Icons.backup_outlined,
            title: l10n.backupReminderShort,
            action: _action(l10n.backupNowShort, _busy ? null : _backupNow),
            onClose: BackupCoordinator.dismissReminder,
          );
        },
      ),
    );
  }
}

/// Franja fina de una línea: icono, mensaje corto, acción y cerrar.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.action,
    this.onClose,
  });

  final Color color;
  final IconData icon;
  final String title;
  final Widget action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 2, 2, 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            action,
            if (onClose != null)
              IconButton(
                tooltip: context.l10n.backupReminderLater,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}
