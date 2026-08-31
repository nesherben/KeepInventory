import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../models/product_model.dart';
import '../../domain/entities/sale.dart';

class LocalDatabaseDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

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

  Future<void> processSale(Sale sale) async {
    final database = await db;

    await database.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'date': sale.date.toIso8601String(),
        'total_amount': sale.totalAmount,
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

  Future<Map<String, double>> getDailySales() async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT date(date) as day, SUM(total_amount) as total 
      FROM sales 
      GROUP BY day 
      ORDER BY day ASC
    ''');

    Map<String, double> dailySales = {};
    for (var row in result) {
      final day = row['day'] as String;
      final total = (row['total'] as num).toDouble();
      dailySales[day] = total;
    }
    return dailySales;
  }

  // NUEVO: Recuperar el historial de tickets con sus horas exactas y productos
  Future<List<Sale>> getSales() async {
    final database = await db;

    // Obtenemos los tickets de más nuevo a más viejo
    final salesMaps = await database.query('sales', orderBy: 'date DESC');

    List<Sale> salesList = [];

    for (var saleMap in salesMaps) {
      final saleId = saleMap['id'] as int;

      // Unimos la tabla de items de venta con la de productos para sacar el nombre real
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
          items: itemsList,
        ),
      );
    }

    return salesList;
  }
}
