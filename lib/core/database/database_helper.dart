import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // 1. Tabla de Promociones (Plantillas globales)
    await db.execute('''
      CREATE TABLE promotions (
        id $idType,
        name $textType,
        type $textType,
        threshold $intType,
        discount_value $realType
      )
    ''');

    // 2. Tabla de Productos (Incluye promotion_id e is_active para borrado lógico)
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        units $intType,
        price $realType,
        cost $realType,
        image_path TEXT,
        promotion_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (promotion_id) REFERENCES promotions (id) ON DELETE SET NULL
      )
    ''');

    // 3. Tabla de Ventas
    await db.execute('''
      CREATE TABLE sales (
        id $idType,
        date $textType,
        total_amount $realType
      )
    ''');

    // 4. Tabla de Detalles de Venta
    await db.execute('''
      CREATE TABLE sale_items (
        id $idType,
        sale_id $intType,
        product_id $intType,
        quantity $intType,
        historical_price $realType,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
      )
    ''');
  }

  // Migrador incremental: asegura que al actualizar la app se adapten las tablas sin perder datos
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          threshold INTEGER NOT NULL,
          discount_value REAL NOT NULL
        )
      ''');
      await db.execute(
        'ALTER TABLE products ADD COLUMN promotion_id INTEGER REFERENCES promotions(id) ON DELETE SET NULL',
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
      );
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
