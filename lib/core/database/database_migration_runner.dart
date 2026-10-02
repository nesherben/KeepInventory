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
