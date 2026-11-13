import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/services/app_preferences.dart';
import '../../../core/services/local_backup_service.dart';

/// Cómo termina la petición del permiso de archivos.
enum BackupPermissionResult {
  /// Se puede escribir en Documentos/KeepInventory (sobrevive a desinstalar).
  granted,

  /// Sin permiso, pero el usuario acepta los riesgos: la copia queda dentro de
  /// la app y no se vuelve a avisar.
  riskAccepted,

  /// Lo ha dejado para más tarde.
  declined,
}

/// Pide el permiso de "Acceso a todos los archivos" justo antes de activar la
/// copia, explicando el motivo. Si no se concede, avisa con un botón a Ajustes
/// y la opción de aceptar el riesgo.
class BackupPermissionFlow {
  const BackupPermissionFlow._();

  static Future<BackupPermissionResult> ensure(BuildContext context) async {
    if (await LocalBackupService.canWriteSharedFolder()) {
      return BackupPermissionResult.granted;
    }
    if (AppPreferences.backupRiskAccepted) {
      return BackupPermissionResult.riskAccepted;
    }
    if (!context.mounted) return BackupPermissionResult.declined;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.folder_open_outlined),
        title: Text(context.l10n.backupPermissionTitle),
        content: Text(context.l10n.backupPermissionExplain),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.backupPermissionContinue),
          ),
        ],
      ),
    );
    // Cancelar en la explicación corta el flujo: no cuenta como aceptar riesgos
    if (proceed != true) return BackupPermissionResult.declined;
    // Android 11+ abre Ajustes y devuelve el control al volver
    if (await LocalBackupService.requestFilesAccess()) {
      return BackupPermissionResult.granted;
    }
    if (!context.mounted) return BackupPermissionResult.declined;

    // Sin permiso: avisa del motivo y ofrece Ajustes o aceptar el riesgo
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.l10n.backupPermissionDeniedTitle),
        content: Text(context.l10n.backupPermissionDeniedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'risk'),
            child: Text(context.l10n.backupAcceptRisk),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'settings'),
            child: Text(context.l10n.backupOpenSettings),
          ),
        ],
      ),
    );
    if (choice == 'settings') {
      // Abre directamente la pantalla "Permitir gestionar todos los archivos"
      // y, si la activa, sigue adelante sin tener que repetir nada
      return await LocalBackupService.requestFilesAccess()
          ? BackupPermissionResult.granted
          : BackupPermissionResult.declined;
    }
    if (choice == 'risk') {
      await AppPreferences.setBackupRiskAccepted(true);
      return BackupPermissionResult.riskAccepted;
    }
    return BackupPermissionResult.declined;
  }
}
