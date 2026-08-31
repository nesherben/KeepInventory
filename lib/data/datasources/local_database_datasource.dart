import 'package:keepinventory/data/models/promotion_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../models/product_model.dart';
import '../../domain/entities/sale.dart';

class LocalDatabaseDatasource {
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

  Future<int> deleteProduct(int id) async {
    final database = await db;
    return await database.update(
      'products',
      {'is_active': 0, 'units': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> processSale(Sale sale) async {
    final database = await db;

    await database.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'date': sale.date.toIso8601String(),
        'total_amount': sale.totalAmount,
        'fair_name': sale.fairName, // Guardamos la feria asociada si la tiene
      });

      for (var item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'historical_price': item.historicalPrice,
        });

        await txn.rawUpdate(
          'UPDATE products SET units = units - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }

  Future<double> getTotalRevenue() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(total_amount) as total FROM sales',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getInventoryCost() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(cost * units) as total FROM products',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getExpectedRevenue() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(price * units) as total FROM products',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Obtener ventas agrupadas por Feria (si tiene) o por Día
  Future<Map<String, double>> getDailySales() async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT 
        COALESCE(fair_name, date(date)) as group_key, 
        SUM(total_amount) as total 
      FROM sales 
      GROUP BY group_key 
      ORDER BY date ASC
    ''');

    Map<String, double> salesGrouped = {};
    for (var row in result) {
      final key = row['group_key'] as String;
      final total = (row['total'] as num).toDouble();
      salesGrouped[key] = total;
    }
    return salesGrouped;
  }

  // Recuperar el historial de tickets con sus ferias y productos
  Future<List<Sale>> getSales() async {
    final database = await db;

    final salesMaps = await database.query('sales', orderBy: 'date DESC');

    List<Sale> salesList = [];

    for (var saleMap in salesMaps) {
      final saleId = saleMap['id'] as int;

      final itemsMaps = await database.rawQuery(
        '''
        SELECT si.*, p.name as product_name 
        FROM sale_items si 
        LEFT JOIN products p ON si.product_id = p.id 
        WHERE si.sale_id = ?
      ''',
        [saleId],
      );

      List<SaleItem> itemsList = itemsMaps
          .map(
            (itemMap) => SaleItem(
              id: itemMap['id'] as int,
              saleId: itemMap['sale_id'] as int,
              productId: itemMap['product_id'] as int,
              productName:
                  itemMap['product_name'] as String? ?? 'Desconocido/Eliminado',
              quantity: itemMap['quantity'] as int,
              historicalPrice: (itemMap['historical_price'] as num).toDouble(),
            ),
          )
          .toList();

      salesList.add(
        Sale(
          id: saleId,
          date: DateTime.parse(saleMap['date'] as String),
          totalAmount: (saleMap['total_amount'] as num).toDouble(),
          fairName: saleMap['fair_name'] as String?, // Leemos la feria
          items: itemsList,
        ),
      );
    }

    return salesList;
  }

  // Devolución inteligente de tickets
  Future<void> refundSale(Sale sale) async {
    final database = await db;

    await database.transaction((txn) async {
      for (var item in sale.items) {
        final List<Map<String, dynamic>> maps = await txn.query(
          'products',
          columns: ['units', 'is_active'],
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (maps.isNotEmpty) {
          final currentUnits = maps.first['units'] as int;
          final restoredUnits = currentUnits + item.quantity;

          await txn.update(
            'products',
            {
              'units': restoredUnits,
              'is_active':
                  1, // Reactiva el producto si estaba borrado lógicamente
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }

      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );
      await txn.delete('sales', where: 'id = ?', whereArgs: [sale.id]);
    });
  }

  // Actualizar el nombre de feria para un día concreto
  Future<void> updateFairNameForDate(
    String datePrefix,
    String? fairName,
  ) async {
    final database = await db;
    await database.rawUpdate(
      'UPDATE sales SET fair_name = ? WHERE date LIKE ?',
      [fairName, '$datePrefix%'],
    );
  }

  // Obtener lista de nombres de ferias ya utilizadas anteriormente
  Future<List<String>> getAvailableFairs() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.rawQuery(
      'SELECT DISTINCT fair_name FROM sales WHERE fair_name IS NOT NULL AND fair_name != ""',
    );
    return maps.map((m) => m['fair_name'] as String).toList();
  }

  // --- Promociones ---
  Future<List<PromotionModel>> getPromotions() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query('promotions');
    return maps.map((map) => PromotionModel.fromMap(map)).toList();
  }

  Future<int> insertPromotion(PromotionModel promotion) async {
    final database = await db;
    return await database.insert('promotions', promotion.toMap());
  }

  Future<int> updatePromotion(PromotionModel promotion) async {
    final database = await db;
    return await database.update(
      'promotions',
      promotion.toMap(),
      where: 'id = ?',
      whereArgs: [promotion.id],
    );
  }

  Future<int> deletePromotion(int id) async {
    final database = await db;
    return await database.delete(
      'promotions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
