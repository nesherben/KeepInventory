import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Por qué una copia no se puede restaurar.
enum BackupProblem {
  /// No se puede abrir o falla la comprobación de integridad.
  corrupt,

  /// No tiene las tablas de la app: no es una copia de KeepInventory.
  notABackup,

  /// Es de una versión de la app más nueva que esta: no se puede migrar hacia
  /// atrás.
  newer,
}

/// Datos de una copia: se leen abriéndola en solo lectura, sin tocarla.
class BackupInfo {
  const BackupInfo({
    required this.path,
    required this.modified,
    required this.sizeBytes,
    this.problem,
    this.appVersion,
    this.schemaVersion = 0,
    this.products = 0,
    this.sales = 0,
    this.otherRows = 0,
  });

  final String path;
  final DateTime modified;
  final int sizeBytes;
  final BackupProblem? problem;

  /// Versión de la app que guardó la copia (null en las anteriores a 1.14.1).
  final String? appVersion;

  /// `PRAGMA user_version` de la copia.
  final int schemaVersion;
  final int products;
  final int sales;

  /// Filas en categorías, ferias, promociones, packs, combos y devoluciones:
  /// una BD solo con esto tampoco está vacía.
  final int otherRows;

  bool get isValid => problem == null;

  /// La copia es de un esquema más antiguo: se migrará al abrirla.
  bool get needsMigration =>
      isValid && schemaVersion < DatabaseHelper.schemaVersion;

  /// Sin ningún dato del usuario: no hay nada que merezca restaurarse.
  bool get isEmpty => products == 0 && sales == 0 && otherRows == 0;
}

class BackupValidator {
  const BackupValidator._();

  /// Tablas con datos del usuario, además de productos y ventas.
  static const _otherDataTables = [
    'categories',
    'fairs',
    'promotions',
    'packs',
    'combos',
    'sale_refunds',
  ];

  /// Cuenta las filas de [tables] que existan en la BD.
  static Future<int> _countRows(
    DatabaseExecutor db,
    Iterable<String> tables,
  ) async {
    var total = 0;
    for (final table in tables) {
      total +=
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $table'),
          ) ??
          0;
    }
    return total;
  }

  /// Abre [file] en solo lectura y comprueba que se pueda restaurar.
  static Future<BackupInfo> inspect(File file) async {
    final stat = await file.stat();
    BackupInfo failed(BackupProblem problem, {int schema = 0}) => BackupInfo(
      path: file.path,
      modified: stat.modified,
      sizeBytes: stat.size,
      problem: problem,
      schemaVersion: schema,
    );

    Database? db;
    try {
      db = await openDatabase(file.path, readOnly: true, singleInstance: false);
      final check = await db.rawQuery('PRAGMA quick_check');
      if (check.isEmpty || check.first.values.first != 'ok') {
        return failed(BackupProblem.corrupt);
      }
      final schema =
          Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')) ?? 0;
      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )).map((row) => row['name']).toSet();
      if (!tables.containsAll(const ['products', 'sales'])) {
        return failed(BackupProblem.notABackup, schema: schema);
      }
      if (schema > DatabaseHelper.schemaVersion) {
        return failed(BackupProblem.newer, schema: schema);
      }
      String? appVersion;
      if (tables.contains('app_meta')) {
        final rows = await db.query(
          'app_meta',
          columns: ['value'],
          where: 'key = ?',
          whereArgs: [DatabaseHelper.appVersionKey],
        );
        appVersion = rows.isEmpty ? null : rows.first['value'] as String?;
      }
      return BackupInfo(
        path: file.path,
        modified: stat.modified,
        sizeBytes: stat.size,
        appVersion: appVersion,
        schemaVersion: schema,
        products:
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM products'),
            ) ??
            0,
        sales:
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM sales'),
            ) ??
            0,
        otherRows: await _countRows(
          db,
          _otherDataTables.where(tables.contains),
        ),
      );
    } catch (e) {
      debugPrint('No se pudo leer la copia ${file.path}: $e');
      return failed(BackupProblem.corrupt);
    } finally {
      await db?.close();
    }
  }

  /// ¿La BD actual tiene algún dato? (decide si es "instalación nueva")
  static Future<bool> currentDatabaseHasData() async {
    final db = await DatabaseHelper.instance.database;
    return await _countRows(db, [
          'products',
          'sales',
          ..._otherDataTables,
        ]) >
        0;
  }
}
