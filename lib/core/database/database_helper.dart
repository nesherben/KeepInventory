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
      version: 11, // Versión 11 con soporte de columnas para promociones en el ticket
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure,
    );
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
