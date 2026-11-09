import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/product_category.dart';

class CategoryLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  Future<List<ProductCategory>> getCategories() async {
    final database = await db;
    final rows = await database.query(
      'categories',
      orderBy: 'name COLLATE NOCASE',
    );
    return [
      for (final r in rows)
        ProductCategory(id: r['id'] as int, name: r['name'] as String),
    ];
  }

  Future<ProductCategory> getOrCreate(String name) async {
    final database = await db;
    final clean = name.trim();
    await database.insert('categories', {
      'name': clean,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final rows = await database.query(
      'categories',
      where: 'name = ?',
      whereArgs: [clean],
      limit: 1,
    );
    return ProductCategory(
      id: rows.first['id'] as int,
      name: rows.first['name'] as String,
    );
  }

  Future<void> delete(int id) async {
    final database = await db;
    await database.transaction((txn) async {
      // Por si las claves foráneas no se aplicaran (BD migradas)
      await txn.update(
        'products',
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'combo_slots',
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> countProducts(int id) async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS n FROM products WHERE category_id = ? AND is_active = 1',
      [id],
    );
    return (rows.first['n'] as int?) ?? 0;
  }
}
