import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/database_migration_runner.dart';
import 'backup_validator.dart';
import 'local_backup_service.dart';
import 'sync_service.dart';

enum RestoreStatus {
  /// Datos sustituidos: hay que reiniciar la app.
  restored,

  /// El archivo está dañado o no es una copia de KeepInventory.
  invalid,

  /// La copia es de una versión de la app más nueva que esta.
  newer,

  /// Falló al copiar: los datos actuales siguen como estaban.
  failed,
}

class RestoreResult {
  const RestoreResult(this.status, {this.info, this.savedBefore});

  final RestoreStatus status;
  final BackupInfo? info;

  /// Copia de los datos que había antes de restaurar (null si estaba vacía).
  final File? savedBefore;
}

/// Sustituye la base de datos por una copia (local o bajada de Drive).
///
/// Antes valida la copia, y guarda una copia persistente de los datos actuales
/// para poder deshacer una restauración equivocada.
class BackupRestoreService {
  const BackupRestoreService._();

  static Future<RestoreResult> restoreFrom(File source) async {
    final info = await BackupValidator.inspect(source);
    if (!info.isValid) {
      return RestoreResult(
        info.problem == BackupProblem.newer
            ? RestoreStatus.newer
            : RestoreStatus.invalid,
        info: info,
      );
    }

    File? saved;
    try {
      // Una restauración no puede cruzarse con un envío por sincronización
      await SyncService.stopServer();
      await DatabaseHelper.instance.resetDatabase();
      saved = await LocalBackupService.saveBeforeRestore();

      final dbFile = await LocalBackupService.databaseFile();
      final temp = File('${dbFile.path}.restore');
      await source.copy(temp.path);
      // Una copia de un esquema anterior se migra AHORA, sobre la copia: si la
      // migración falla no se toca la BD actual
      if (info.needsMigration && !await _migrates(temp)) {
        await temp.delete();
        await _putBack(saved);
        return RestoreResult(RestoreStatus.invalid, info: info);
      }
      // Restos de la BD anterior que SQLite mezclaría con la nueva
      for (final suffix in const ['-journal', '-wal', '-shm']) {
        final leftover = File('${dbFile.path}$suffix');
        if (await leftover.exists()) await leftover.delete();
      }
      if (await dbFile.exists()) await dbFile.delete();
      await temp.rename(dbFile.path);
      return RestoreResult(
        RestoreStatus.restored,
        info: info,
        savedBefore: saved,
      );
    } catch (e) {
      debugPrint('Error al restaurar la copia: $e');
      await _putBack(saved);
      return RestoreResult(RestoreStatus.failed, info: info);
    }
  }

  /// Abre [file] con el esquema actual (lo migra) y comprueba que funcione.
  static Future<bool> _migrates(File file) async {
    Database? db;
    try {
      db = await openDatabase(
        file.path,
        version: DatabaseHelper.schemaVersion,
        singleInstance: false,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onUpgrade: (db, oldVersion, newVersion) =>
            DatabaseMigrationRunner.upgrade(
              oldVersion: oldVersion,
              execute: (sql) => db.execute(sql),
              query: (sql) => db.rawQuery(sql),
            ),
      );
      return true;
    } catch (e) {
      debugPrint('La copia no se pudo migrar: $e');
      return false;
    } finally {
      await db?.close();
    }
  }

  /// Si la restauración falla a medias, vuelven los datos de antes.
  static Future<void> _putBack(File? saved) async {
    try {
      final dbFile = await LocalBackupService.databaseFile();
      final temp = File('${dbFile.path}.restore');
      if (await temp.exists()) await temp.delete();
      if (saved != null && !await dbFile.exists()) {
        await saved.copy(dbFile.path);
      }
    } catch (e) {
      debugPrint('No se pudo devolver la BD anterior: $e');
    }
  }
}
