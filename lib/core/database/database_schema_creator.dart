class DatabaseSchemaCreator {
  const DatabaseSchemaCreator._();

  static Future<void> create({
    required Future<void> Function(String sql) execute,
  }) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

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
        FOREIGN KEY (promotion_id) REFERENCES promotions (id) ON DELETE SET NULL
      )
    ''');

    await execute('''
      CREATE TABLE sales (
        id $idType,
        date $textType,
        total_amount $realType,
        fair_name TEXT
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
  }
}
