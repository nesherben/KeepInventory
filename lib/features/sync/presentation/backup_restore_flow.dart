import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';
import 'package:restart_app/restart_app.dart';

import '../../../core/services/backup_restore_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/backup_validator.dart';
import '../../../core/services/drive_backup_service.dart';
import '../../../core/services/local_backup_service.dart';
import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/utils/backup_formatters.dart';

/// Ejecuta una operación de datos bloqueando navegación e interacción.
Future<T> runWithBlockingProgress<T>(
  BuildContext context, {
  required String title,
  required Future<T> Function(void Function(double) reportProgress) task,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final progress = ValueNotifier<double?>(null);
  final dialog = showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value),
              if (value != null) ...[
                const SizedBox(height: 12),
                Text('${(value * 100).round()}%'),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await task((value) => progress.value = value.clamp(0.0, 1.0));
  } finally {
    if (navigator.mounted && navigator.canPop()) navigator.pop();
    await dialog;
    progress.dispose();
  }
}

/// Diálogo "datos restaurados": hay que reiniciar para abrir la BD nueva.
Future<void> showRestoredDialog(BuildContext context) {
  return showDialog(
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
          onPressed: Restart.restartApp,
          child: Text(context.l10n.restartNow),
        ),
      ],
    ),
  );
}

/// Valida [file], pide confirmación (con fecha y resumen) y lo restaura.
/// Antes de sustituir los datos se guarda una copia de los actuales.
/// [date] es la fecha que se muestra (la de Drive; la del archivo si es null).
/// [deleteAfter] indica que es una descarga temporal de Drive: se borra al
/// terminar y la restauración cuenta como copia de Drive, no del móvil.
/// Devuelve true si se restauró (y queda el diálogo de reinicio abierto).
Future<bool> confirmAndRestore(
  BuildContext context,
  File file, {
  DateTime? date,
  bool deleteAfter = false,
}) async {
  try {
    return await _confirmAndRestore(
      context,
      file,
      date: date,
      fromDrive: deleteAfter,
    );
  } finally {
    // Descarga temporal de Drive: no se deja en el móvil
    if (deleteAfter) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}

Future<bool> _confirmAndRestore(
  BuildContext context,
  File file, {
  DateTime? date,
  required bool fromDrive,
}) async {
  final info = await BackupValidator.inspect(file);
  if (!context.mounted) return false;
  if (!info.isValid) {
    final message = info.problem == BackupProblem.newer
        ? context.l10n.backupRestoreNewer
        : context.l10n.backupRestoreInvalid;
    AppAlerts.showError(context, message);
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      final colors = Theme.of(context).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.restore, color: colors.error),
        title: Text(l10n.backupRestoreConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupRestoreConfirmBody(
                info.products,
                info.sales,
                formatBackupDate(context, date ?? info.modified),
              ),
            ),
            if (info.needsMigration) ...[
              const SizedBox(height: 12),
              Text(
                l10n.backupRestoreOlderVersion(info.appVersion ?? '?'),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.backupRestoreConfirmButton),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;

  final result = await runWithBlockingProgress(
    context,
    title: context.l10n.backupOperationRestoring,
    task: (_) async {
      final result = await BackupRestoreService.restoreFrom(file);
      if (result.status == RestoreStatus.restored) {
        await AppPreferences.markTutorialSeen();
        final signature = await LocalBackupService.currentSignature();
        if (signature != null) {
          final at = (date ?? info.modified).millisecondsSinceEpoch;
          if (fromDrive) {
            await AppPreferences.recordDriveBackup(at, signature);
          } else {
            await AppPreferences.recordLocalBackup(at, signature);
          }
        }
      }
      return result;
    },
  );
  if (!context.mounted) return false;
  switch (result.status) {
    case RestoreStatus.restored:
      await showRestoredDialog(context);
      return true;
    case RestoreStatus.invalid:
      AppAlerts.showError(context, context.l10n.backupRestoreInvalid);
    case RestoreStatus.newer:
      AppAlerts.showError(context, context.l10n.backupRestoreNewer);
    case RestoreStatus.failed:
      AppAlerts.showError(context, context.l10n.restoreFailed);
  }
  return false;
}

/// Mensaje para un fallo de Drive (cancelado, sin conexión, sin configurar…).
void showDriveError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final l10n = context.l10n;
  final failure = error is DriveException ? error.failure : DriveFailure.failed;
  switch (failure) {
    case DriveFailure.cancelled:
      AppAlerts.showInfo(context, l10n.driveSignInCancelled);
    case DriveFailure.offline:
      AppAlerts.showWarning(context, l10n.driveErrorOffline);
    case DriveFailure.notConfigured:
      AppAlerts.showInfo(context, l10n.driveNotConfiguredBody);
    case DriveFailure.failed:
      AppAlerts.showError(context, l10n.driveErrorGeneric);
  }
}

/// Restaura la copia de Drive: inicia sesión si hace falta, la baja, pide
/// confirmación y la restaura. Devuelve true si se restauró.
Future<bool> restoreFromDrive(BuildContext context) async {
  final service = DriveBackupService();
  try {
    if (AppPreferences.driveEmail == null) await DriveBackupService.signIn();
    final info = await service.findBackup();
    if (!context.mounted) return false;
    if (info == null) {
      AppAlerts.showInfo(context, context.l10n.driveNoBackups);
      return false;
    }
    final file = await runWithBlockingProgress(
      context,
      title: context.l10n.backupOperationDownloading,
      task: (reportProgress) =>
          service.download(info, onProgress: reportProgress),
    );
    if (!context.mounted) return false;
    return await confirmAndRestore(
      context,
      file,
      date: info.modified,
      deleteAfter: true,
    );
  } catch (e) {
    if (context.mounted) showDriveError(context, e);
    return false;
  }
}
