import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../product_model.dart';

class ProductLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  Future<List<ProductModel>> getProducts() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'products',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertProduct(ProductModel product) async {
    final database = await db;
    return await database.insert('products', product.toMap());
  }

  Future<int> updateProduct(ProductModel product) async {
    final database = await db;
    return await database.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Actualiza solo las columnas indicadas (no pisa el resto del producto).
  Future<int> updateFields(int id, Map<String, Object?> values) async {
    if (values.isEmpty) return 0;
    final database = await db;
    return database.update(
      'products',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Suma (o resta) unidades en una sola operación, sin bajar de 0.
  Future<void> addUnits(int id, int delta) async {
    if (delta == 0) return;
    final database = await db;
    await database.rawUpdate(
      'UPDATE products SET units = MAX(0, units + ?) WHERE id = ?',
      [delta, id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final database = await db;
    // Borrado lógico para no romper el historial de tickets antiguos
    return await database.update(
      'products',
      {'is_active': 0, 'units': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
