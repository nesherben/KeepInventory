import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'app_version.dart';

/// Resultado de restaurar un backup.
enum BackupImportStatus {
  /// Restaurado (misma versión de la app).
  restored,

  /// El usuario no eligió archivo o falló la copia: no ha cambiado nada.
  failed,

  /// El backup es de otra versión de la app: se ha deshecho, no ha cambiado nada.
  versionMismatch,

  /// El backup no lleva versión (anterior a 1.14.1): queda pendiente de
  /// [DatabaseBackupService.confirmPendingImport] o
  /// [DatabaseBackupService.rollbackPendingImport].
  unknownVersion,
}

class BackupImportResult {
  const BackupImportResult(this.status, {this.backupVersion, this.appVersion});

  final BackupImportStatus status;
  final String? backupVersion;
  final String? appVersion;
}

class DatabaseBackupService {
  static const platform = MethodChannel('com.example.keepinventory/database');

  static Future<String> _getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'keepinventory.db');
  }

  /// Si antes de restaurar no había datos, deshacer = borrar el archivo.
  static bool _hadOriginal = true;

  static Future<File> _failsafeFile() async =>
      File(join(await getDatabasesPath(), 'keepinventory_restore_failsafe.db'));

  /// EXPORTAR
  static Future<bool> exportDatabase() async {
    try {
      // Al cerrar, SQLite coge todo el WAL y lo guarda físicamente en el archivo
      await DatabaseHelper.instance.resetDatabase();

      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        debugPrint('La base de datos no existe.');
        return false;
      }

      final bool success = await platform.invokeMethod('saveDatabase', {
        'sourcePath': dbFile.path,
      });

      return success;
    } catch (e) {
      debugPrint('Error al exportar: $e');
      return false;
    }
  }

  /// IMPORTAR / RESTAURAR. Se guarda una copia de los datos actuales y, tras
  /// restaurar, se comprueba que el backup sea de la misma versión de la app;
  /// si no lo es, se vuelve a la copia.
  static Future<BackupImportResult> importDatabase() async {
    final dbFile = File(await _getDatabasePath());
    final failsafe = await _failsafeFile();
    try {
      // 1. Cerramos la conexión y guardamos una copia de los datos actuales
      await DatabaseHelper.instance.resetDatabase();
      if (await failsafe.exists()) await failsafe.delete();
      _hadOriginal = await dbFile.exists();
      if (_hadOriginal) await dbFile.copy(failsafe.path);

      // 2. Android sustituye el archivo por el backup elegido
      final bool success = await platform.invokeMethod('restoreDatabase');
      if (!success) {
        await _discardFailsafe();
        return const BackupImportResult(BackupImportStatus.failed);
      }

      // 3. ¿De qué versión es el backup?
      final mine = await AppVersion.current();
      final theirs = await DatabaseHelper.readAppVersionOf(dbFile.path);
      switch (AppVersion.compare(theirs, mine)) {
        case VersionMatch.same:
          await _discardFailsafe();
          return BackupImportResult(
            BackupImportStatus.restored,
            backupVersion: theirs,
            appVersion: mine,
          );
        case VersionMatch.different:
          await rollbackPendingImport();
          return BackupImportResult(
            BackupImportStatus.versionMismatch,
            backupVersion: theirs,
            appVersion: mine,
          );
        case VersionMatch.unknown:
          return BackupImportResult(
            BackupImportStatus.unknownVersion,
            appVersion: mine,
          );
      }
    } catch (e) {
      debugPrint('Error al importar: $e');
      await rollbackPendingImport();
      return const BackupImportResult(BackupImportStatus.failed);
    }
  }

  /// El usuario acepta restaurar un backup sin versión.
  static Future<void> confirmPendingImport() => _discardFailsafe();

  /// Deshace la restauración: vuelven los datos que había antes.
  static Future<void> rollbackPendingImport() async {
    final failsafe = await _failsafeFile();
    final dbFile = File(await _getDatabasePath());
    await DatabaseHelper.instance.resetDatabase();
    if (await failsafe.exists()) {
      await failsafe.copy(dbFile.path);
      await failsafe.delete();
    } else if (!_hadOriginal && await dbFile.exists()) {
      await dbFile.delete();
    }
  }

  static Future<void> _discardFailsafe() async {
    final failsafe = await _failsafeFile();
    if (await failsafe.exists()) await failsafe.delete();
  }
}
