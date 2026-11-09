class DatabaseSchemaCreator {
  const DatabaseSchemaCreator._();

  /// v13: combos (precio fijo por completar huecos) y combos aplicados en
  /// ventas, con la definición congelada en JSON. Compartido con la migración.
  static const comboTables = [
    '''
      CREATE TABLE IF NOT EXISTS combos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS combo_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        combo_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        position INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (combo_id) REFERENCES combos (id) ON DELETE CASCADE
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS combo_slot_products (
        slot_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        PRIMARY KEY (slot_id, product_id),
        FOREIGN KEY (slot_id) REFERENCES combo_slots (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS sale_combos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        combo_id INTEGER,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        definition TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''',
  ];

  /// v14: metadatos del archivo. `app_version` = versión de la app que lo
  /// abrió por última vez (para exigir la misma versión en backups/sync).
  static const metaTable = '''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''';

  /// v15: catálogo de ferias. Las ventas guardan el nombre en
  /// `sales.fair_name`; el catálogo permite tener ferias sin tickets.
  static const fairsTable = '''
      CREATE TABLE IF NOT EXISTS fairs (
        name TEXT PRIMARY KEY COLLATE NOCASE
      )
    ''';

  /// v16: categorías de producto (opcionales). Un hueco de combo puede ser
  /// "cualquier producto de la categoría X".
  static const categoriesTable = '''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE
      )
    ''';

  /// v17: devoluciones parciales de cada venta (para verlas en el ticket).
  static const saleRefundsTable = '''
      CREATE TABLE IF NOT EXISTS sale_refunds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        summary TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''';

  static Future<void> create({
    required Future<void> Function(String sql) execute,
  }) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await execute(categoriesTable);

    await execute('''
      CREATE TABLE promotions (
        id $idType,
        name $textType,
        type $textType,
        threshold $intType,
        discount_value $realType
      )
    ''');

    await execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        units $intType,
        price $realType,
        cost $realType,
        image_path TEXT,
        image_bytes BLOB,
        promotion_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        category_id INTEGER REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (promotion_id) REFERENCES promotions (id) ON DELETE SET NULL
      )
    ''');

    await execute('''
      CREATE TABLE sales (
        id $idType,
        date $textType,
        total_amount $realType,
        fair_name TEXT,
        payment_method TEXT
      )
    ''');

    await execute('''
      CREATE TABLE sale_items (
        id $idType,
        sale_id $intType,
        product_id $intType,
        quantity $intType,
        historical_price $realType,
        original_price REAL DEFAULT 0.0,
        promotion_id INTEGER,
        promo_type TEXT,
        promo_threshold INTEGER,
        promo_discount REAL,
        sale_combo_id INTEGER,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
      )
    ''');

    await execute('''
      CREATE TABLE packs (
        id $idType,
        name $textType,
        price $realType,
        units INTEGER NOT NULL DEFAULT 1,
        image_path TEXT,
        image_bytes BLOB
      )
    ''');

    await execute('''
      CREATE TABLE pack_items (
        id $idType,
        pack_id $intType,
        product_id $intType,
        quantity $intType,
        FOREIGN KEY (pack_id) REFERENCES packs (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
      )
    ''');

    await execute('''
      CREATE TABLE sale_packs (
        id $idType,
        sale_id $intType,
        pack_id $intType,
        quantity $intType,
        historical_price $realType,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (pack_id) REFERENCES packs (id) ON DELETE CASCADE
      )
    ''');

    for (final sql in comboTables) {
      await execute(sql);
    }

    await execute(metaTable);
    await execute(fairsTable);
    await execute(saleRefundsTable);
  }
}
