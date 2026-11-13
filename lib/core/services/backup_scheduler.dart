import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'app_preferences.dart';
import 'local_backup_service.dart';

const _taskName = 'dailyLocalBackup';
const _uniqueNamePrefix = 'keepinventory.dailyLocalBackup';

/// Nombre de la tarea de la medianoche [target]. Alterna entre dos según el día
/// para que la tarea que está corriendo (la de hoy) no se cancele a sí misma al
/// programar la de mañana con `replace`.
String backupTaskNameFor(DateTime target) {
  final days = DateTime.utc(
    target.year,
    target.month,
    target.day,
  ).difference(DateTime.utc(1970)).inDays;
  return '$_uniqueNamePrefix.${days % 2}';
}

/// Punto de entrada de la tarea en segundo plano (WorkManager).
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await AppPreferences.load();
      if (!AppPreferences.autoBackupEnabled) return true;
      final result = await LocalBackupService.createBackup();
      if (result.status == LocalBackupStatus.failed) {
        await AppPreferences.recordBackupFailure();
      }
    } catch (e) {
      debugPrint('Error en la copia de medianoche: $e');
      await AppPreferences.recordBackupFailure();
    }
    // Queda lista la siguiente de las 00:00. Se devuelve siempre true: la
    // siguiente ya está programada y no queremos reintentos en cadena.
    await BackupScheduler.schedule();
    return true;
  });
}

/// Programa la copia automática hacia las 00:00.
///
/// Android no garantiza la hora exacta (ahorro de batería, móvil apagado):
/// por eso también se copia al abrir y al pasar la app a segundo plano.
class BackupScheduler {
  const BackupScheduler._();

  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(backupCallbackDispatcher);
    } catch (e) {
      debugPrint('No se pudo iniciar WorkManager: $e');
    }
  }

  /// Registra la próxima copia a las 00:00 (sustituye la anterior).
  static Future<void> schedule() async {
    try {
      final now = DateTime.now();
      final target = LocalBackupService.nextMidnight(now);
      final delay = target.difference(now);
      await Workmanager().registerOneOffTask(
        backupTaskNameFor(target),
        _taskName,
        initialDelay: delay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint('No se pudo programar la copia: $e');
    }
  }

  static Future<void> cancel() async {
    try {
      await Workmanager().cancelByUniqueName('$_uniqueNamePrefix.0');
      await Workmanager().cancelByUniqueName('$_uniqueNamePrefix.1');
    } catch (e) {
      debugPrint('No se pudo cancelar la copia programada: $e');
    }
  }
}
