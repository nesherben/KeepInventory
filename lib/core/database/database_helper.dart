import '../services/app_version.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_migration_runner.dart';
import 'database_schema_creator.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('keepinventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 17, // Versión 17: devoluciones visibles en el ticket
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure,
      onOpen: _stampAppVersion,
    );
  }

  /// Marca el archivo con la versión de la app que lo abre: así un backup o
  /// una copia sincronizada saben de qué versión vienen.
  Future<void> _stampAppVersion(Database db) async {
    await db.insert('app_meta', {
      'key': appVersionKey,
      'value': await AppVersion.current(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static const appVersionKey = 'app_version';

  /// Lee la versión de la app guardada en un archivo de base de datos
  /// (null si no la tiene: archivo de una versión anterior a la 1.14.1).
  static Future<String?> readAppVersionOf(String path) async {
    Database? db;
    try {
      db = await openDatabase(path, readOnly: true, singleInstance: false);
      final rows = await db.query(
        'app_meta',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [appVersionKey],
      );
      return rows.isEmpty ? null : rows.first['value'] as String?;
    } catch (_) {
      return null;
    } finally {
      await db?.close();
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) {
    return DatabaseSchemaCreator.create(execute: (sql) => db.execute(sql));
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) {
    return DatabaseMigrationRunner.upgrade(
      oldVersion: oldVersion,
      execute: (sql) => db.execute(sql),
      query: (sql) => db.rawQuery(sql),
    );
  }

  // Cierra y limpia la memoria de la conexión actual
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database =
          null; // 💡 ESTA ES LA CLAVE: Obliga a recargar el archivo nuevo
    }
  }

  Future<void> deleteDatabaseFile() async {
    final path = join(await getDatabasesPath(), 'keepinventory.db');
    await resetDatabase();
    await deleteDatabase(path);
  }

  Future<void> close() async {
    await resetDatabase();
  }
}
