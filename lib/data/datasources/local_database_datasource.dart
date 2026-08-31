import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../models/product_model.dart';
import '../../domain/entities/sale.dart';

class LocalDatabaseDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  // --- Productos ---
  Future<List<ProductModel>> getProducts() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query('products');
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

  Future<int> deleteProduct(int id) async {
    final database = await db;
    return await database.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Ventas (Transacción) ---
  Future<void> processSale(Sale sale) async {
    final database = await db;

    // Usamos una transacción para asegurar que todo se guarda o nada se guarda
    await database.transaction((txn) async {
      // 1. Insertar la venta
      final saleId = await txn.insert('sales', {
        'date': sale.date.toIso8601String(),
        'total_amount': sale.totalAmount,
      });

      // 2. Insertar los items y actualizar el stock
      for (var item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'historical_price': item.historicalPrice,
        });

        // Actualizar stock: restar las unidades vendidas
        await txn.rawUpdate(
          'UPDATE products SET units = units - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }
}
