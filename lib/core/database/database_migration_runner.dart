import 'database_schema_creator.dart';

typedef DatabaseSqlExecutor = Future<void> Function(String sql);
typedef DatabaseMetadataQuery = Future<List<Map<String, Object?>>> Function(
  String sql,
);

class DatabaseMigrationRunner {
  const DatabaseMigrationRunner._();

  static Future<void> upgrade({
    required int oldVersion,
    required DatabaseSqlExecutor execute,
    required DatabaseMetadataQuery query,
  }) async {
    await _upgradePromotions(oldVersion, execute);
    await _upgradeProductActivity(oldVersion, execute);
    await _upgradeFairNames(oldVersion, execute, query);
    await _upgradePacks(oldVersion, execute);
    await _upgradeSalePacks(oldVersion, execute);
    await _upgradePackUnits(oldVersion, execute);
    await _upgradeRefundDetails(oldVersion, execute);
    await _repairPromotionDetails(oldVersion, execute);
    await _upgradeImageBlobs(oldVersion, execute);
    await _upgradePaymentMethod(oldVersion, execute);
    await _upgradeCombos(oldVersion, execute);
    await _upgradeAppMeta(oldVersion, execute);
    await _upgradeFairsCatalog(oldVersion, execute);
    await _upgradeCategories(oldVersion, execute);
    await _upgradeSaleRefunds(oldVersion, execute);
  }

  /// v17: historial de devoluciones parciales por venta.
  static Future<void> _upgradeSaleRefunds(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 17) return;
    await execute(DatabaseSchemaCreator.saleRefundsTable);
  }

  static const productCategoryAlter =
      'ALTER TABLE products ADD COLUMN category_id INTEGER '
      'REFERENCES categories (id) ON DELETE SET NULL';
  static const slotCategoryAlter =
      'ALTER TABLE combo_slots ADD COLUMN category_id INTEGER '
      'REFERENCES categories (id) ON DELETE CASCADE';

  /// v16: categorías de producto y huecos de combo por categoría.
  static Future<void> _upgradeCategories(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 16) return;
    await execute(DatabaseSchemaCreator.categoriesTable);
    try {
      await execute(productCategoryAlter);
    } catch (_) {}
    try {
      await execute(slotCategoryAlter);
    } catch (_) {}
  }

  static const seedFairsFromSales = '''
      INSERT OR IGNORE INTO fairs (name)
      SELECT DISTINCT TRIM(fair_name) FROM sales
      WHERE fair_name IS NOT NULL AND TRIM(fair_name) != ''
    ''';

  /// v15: catálogo de ferias, relleno con las que ya usan las ventas.
  static Future<void> _upgradeFairsCatalog(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 15) return;
    await execute(DatabaseSchemaCreator.fairsTable);
    await execute(seedFairsFromSales);
  }

  /// v14: tabla de metadatos (versión de la app que escribió el archivo).
  static Future<void> _upgradeAppMeta(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 14) return;
    await execute(DatabaseSchemaCreator.metaTable);
  }

  static const saleComboColumnAlter =
      'ALTER TABLE sale_items ADD COLUMN sale_combo_id INTEGER';

  /// v13: combos. Las ventas existentes quedan sin combo (NULL).
  static Future<void> _upgradeCombos(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 13) return;

    for (final sql in DatabaseSchemaCreator.comboTables) {
      await execute(sql);
    }
    try {
      await execute(saleComboColumnAlter);
    } catch (_) {}
  }

  /// v12: método de pago por venta. Las ventas existentes quedan en NULL ("sin especificar").
  static Future<void> _upgradePaymentMethod(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 12) return;

    try {
      await execute('ALTER TABLE sales ADD COLUMN payment_method TEXT');
    } catch (_) {}
  }

  static Future<void> _upgradePromotions(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 2) return;

    await execute('''
      CREATE TABLE IF NOT EXISTS promotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        threshold INTEGER NOT NULL,
        discount_value REAL NOT NULL
      )
    ''');
    await execute(
      'ALTER TABLE products ADD COLUMN promotion_id INTEGER REFERENCES promotions(id) ON DELETE SET NULL',
    );
  }

  static Future<void> _upgradeProductActivity(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 3) return;
    await execute(
      'ALTER TABLE products ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
    );
  }

  static Future<void> _upgradeFairNames(
    int oldVersion,
    DatabaseSqlExecutor execute,
    DatabaseMetadataQuery query,
  ) async {
    if (oldVersion >= 4) return;

    try {
      final columns = await query('PRAGMA table_info(sales)');
      final hasFairName = columns.any(
        (column) => column['name'] == 'fair_name',
      );
      if (!hasFairName) {
        await execute('ALTER TABLE sales ADD COLUMN fair_name TEXT');
      }
    } catch (_) {
      try {
        await execute('ALTER TABLE sales ADD COLUMN fair_name TEXT');
      } catch (_) {}
    }
  }

  static Future<void> _upgradePacks(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 5) return;

    await execute('''
      CREATE TABLE IF NOT EXISTS packs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        image_path TEXT
      )
    ''');
    await execute('''
      CREATE TABLE IF NOT EXISTS pack_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pack_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (pack_id) REFERENCES packs (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
      )
    ''');
  }

  static Future<void> _upgradeSalePacks(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 6) return;

    await execute('''
      CREATE TABLE IF NOT EXISTS sale_packs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        pack_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        historical_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (pack_id) REFERENCES packs (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _upgradePackUnits(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 7) return;
    try {
      await execute(
        'ALTER TABLE packs ADD COLUMN units INTEGER NOT NULL DEFAULT 1',
      );
    } catch (_) {}
  }

  static Future<void> _upgradeRefundDetails(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 8) return;

    try {
      await execute(
        'ALTER TABLE sale_items ADD COLUMN original_price REAL DEFAULT 0.0',
      );
    } catch (_) {}

    try {
      await execute('ALTER TABLE sale_items ADD COLUMN promotion_id INTEGER');
    } catch (_) {}
  }

  static Future<void> _repairPromotionDetails(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion < 9) {
      try {
        await execute('ALTER TABLE sale_items ADD COLUMN promo_type TEXT');
        await execute(
          'ALTER TABLE sale_items ADD COLUMN promo_threshold INTEGER',
        );
        await execute('ALTER TABLE sale_items ADD COLUMN promo_discount REAL');
      } catch (_) {}
    }

    if (oldVersion < 10) {
      try {
        await execute('ALTER TABLE sale_items ADD COLUMN promo_type TEXT');
      } catch (_) {}

      try {
        await execute(
          'ALTER TABLE sale_items ADD COLUMN promo_threshold INTEGER',
        );
      } catch (_) {}

      try {
        await execute('ALTER TABLE sale_items ADD COLUMN promo_discount REAL');
      } catch (_) {}
    }
  }

  static Future<void> _upgradeImageBlobs(
    int oldVersion,
    DatabaseSqlExecutor execute,
  ) async {
    if (oldVersion >= 11) return;

    try {
      await execute('ALTER TABLE products ADD COLUMN image_bytes BLOB');
    } catch (_) {}

    try {
      await execute('ALTER TABLE packs ADD COLUMN image_bytes BLOB');
    } catch (_) {}
  }
}
