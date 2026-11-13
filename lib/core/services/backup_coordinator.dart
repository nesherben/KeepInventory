import 'package:flutter/foundation.dart';

import 'app_preferences.dart';
import 'backup_scheduler.dart';
import 'backup_validator.dart';
import 'local_backup_service.dart';

/// Decide cuándo se hace la copia automática más allá de las 00:00: al abrir
/// la app y al pasarla a segundo plano.
class BackupCoordinator {
  BackupCoordinator._();

  /// Hay que avisar en el dashboard: cambios sin copiar y última copia vieja.
  static final ValueNotifier<bool> reminderNeeded = ValueNotifier(false);

  /// Cuántas copias automáticas han fallado seguidas (se avisa desde 2).
  static final ValueNotifier<int> failures = ValueNotifier(0);

  /// Sube cada vez que cambia el estado de las copias (copia local, subida a
  /// Drive…): las pantallas que lo muestran se refrescan al escucharlo.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// El usuario cerró el aviso en esta sesión.
  static bool _dismissed = false;

  static DateTime? _lastAttempt;

  static void dismissReminder() {
    _dismissed = true;
    reminderNeeded.value = false;
  }

  /// Al abrir la app (y al volver a ella).
  static Future<void> onAppStarted() async {
    try {
      await _onAppStarted();
    } catch (e) {
      debugPrint('Error al preparar las copias al abrir: $e');
    }
  }

  static Future<void> _onAppStarted() async {
    await AppPreferences.load();
    if (AppPreferences.autoBackupEnabled) {
      await BackupScheduler.schedule();
      final due = await _reminderDue();
      // Copia silenciosa; si falla, queda el aviso
      if (due) {
        final result = await LocalBackupService.createBackup();
        if (result.status == LocalBackupStatus.failed) {
          await AppPreferences.recordBackupFailure();
        }
      }
    }
    await refresh();
  }

  /// Al pasar la app a segundo plano: copia silenciosa si hay cambios.
  static Future<void> onAppPaused() async {
    // La tarea de medianoche pudo escribir en otro isolate
    await AppPreferences.load();
    if (!AppPreferences.autoBackupEnabled) return;
    final now = DateTime.now();
    final last = _lastAttempt;
    // Sin ráfagas: como mucho una copia cada 2 minutos
    if (last != null && now.difference(last) < const Duration(minutes: 2)) {
      return;
    }
    _lastAttempt = now;
    final result = await LocalBackupService.createBackup();
    if (result.status == LocalBackupStatus.failed) {
      await AppPreferences.recordBackupFailure();
    }
    await refresh();
  }

  /// Recalcula el aviso del dashboard.
  static Future<void> refresh() async {
    try {
      failures.value = AppPreferences.backupFailures;
      reminderNeeded.value = await _reminderDue() && !_dismissed;
    } catch (e) {
      debugPrint('No se pudo calcular el aviso de copia: $e');
    }
    revision.value++;
  }

  /// Hay datos, cambios sin copiar y la última copia es de hace más de un día.
  /// Con la BD vacía (instalación nueva) no hay nada que avisar.
  static Future<bool> _reminderDue() async {
    if (!await BackupValidator.currentDatabaseHasData()) return false;
    return LocalBackupService.reminderDue(
      hasChanges: await LocalBackupService.hasUnsavedChanges(),
      lastBackupAt: AppPreferences.lastLocalBackupAt,
      now: DateTime.now(),
    );
  }
}
