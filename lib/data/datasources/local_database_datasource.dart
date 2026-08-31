import 'package:keepinventory/data/models/promotion_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../models/product_model.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/pack.dart';

class LocalDatabaseDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  // ==========================================
  // --- PRODUCTOS ---
  // ==========================================
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

  // ==========================================
  // --- PACKS Y BUNDLES ---
  // ==========================================
  Future<List<Pack>> getPacks() async {
    final database = await db;
    final packMaps = await database.query('packs');
    List<Pack> packs = [];

    for (var pMap in packMaps) {
      final packId = pMap['id'] as int;

      final itemsResult = await database.rawQuery(
        '''
        SELECT pi.product_id, pi.quantity, pr.name as product_name
        FROM pack_items pi
        JOIN products pr ON pi.product_id = pr.id
        WHERE pi.pack_id = ?
      ''',
        [packId],
      );

      List<PackItem> items = itemsResult
          .map(
            (iMap) => PackItem(
              productId: iMap['product_id'] as int,
              productName: iMap['product_name'] as String,
              quantity: iMap['quantity'] as int,
            ),
          )
          .toList();

      packs.add(
        Pack(
          id: packId,
          name: pMap['name'] as String,
          price: (pMap['price'] as num).toDouble(),
          units: pMap['units'] as int? ?? 1,
          imagePath: pMap['image_path'] as String?,
          items: items,
        ),
      );
    }

    return packs;
  }

  Future<void> createPack(Pack pack) async {
    final database = await db;
    await database.transaction((txn) async {
      // 1. Insertar pack principal con sus unidades
      final packId = await txn.insert('packs', {
        'name': pack.name,
        'price': pack.price,
        'units': pack.units,
        'image_path': pack.imagePath,
      });

      // 2. Insertar componentes y descontar del inventario principal (cantidad_item * unidades_pack)
      for (var item in pack.items) {
        await txn.insert('pack_items', {
          'pack_id': packId,
          'product_id': item.productId,
          'quantity': item.quantity,
        });

        final totalDeduction = item.quantity * pack.units;
        await txn.rawUpdate(
          'UPDATE products SET units = units - ? WHERE id = ?',
          [totalDeduction, item.productId],
        );
      }
    });
  }

  Future<void> updatePack(Pack oldPack, Pack newPack) async {
    final database = await db;
    await database.transaction((txn) async {
      // 1. Devolver el stock antiguo al inventario principal
      for (var oldItem in oldPack.items) {
        final totalReturn = oldItem.quantity * oldPack.units;
        await txn.rawUpdate(
          'UPDATE products SET units = units + ? WHERE id = ?',
          [totalReturn, oldItem.productId],
        );
      }

      // 2. Borrar relaciones de componentes antiguos
      await txn.delete(
        'pack_items',
        where: 'pack_id = ?',
        whereArgs: [oldPack.id],
      );

      // 3. Actualizar datos y nuevas unidades del pack
      await txn.update(
        'packs',
        {
          'name': newPack.name,
          'price': newPack.price,
          'units': newPack.units,
          'image_path': newPack.imagePath,
        },
        where: 'id = ?',
        whereArgs: [oldPack.id],
      );

      // 4. Insertar nuevos componentes y descontar el nuevo stock requerido
      for (var newItem in newPack.items) {
        await txn.insert('pack_items', {
          'pack_id': oldPack.id,
          'product_id': newItem.productId,
          'quantity': newItem.quantity,
        });

        final totalDeduction = newItem.quantity * newPack.units;
        await txn.rawUpdate(
          'UPDATE products SET units = units - ? WHERE id = ?',
          [totalDeduction, newItem.productId],
        );
      }
    });
  }

  Future<void> deletePack(Pack pack) async {
    final database = await db;
    await database.transaction((txn) async {
      // Devolver los componentes no vendidos al almacén principal
      for (var item in pack.items) {
        final totalReturn = item.quantity * pack.units;
        await txn.rawUpdate(
          'UPDATE products SET units = units + ? WHERE id = ?',
          [totalReturn, item.productId],
        );
      }
      await txn.delete('packs', where: 'id = ?', whereArgs: [pack.id]);
    });
  }

  // ==========================================
  // --- VENTAS Y TPV ---
  // ==========================================
  Future<void> processSale(Sale sale) async {
    final database = await db;

    await database.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'date': sale.date.toIso8601String(),
        'total_amount': sale.totalAmount,
        'fair_name': sale.fairName,
      });

      // 1. Procesar productos individuales (descuenta stock físico)
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

      // 2. Procesar packs vendidos (descuenta unidades montadas del pack)
      for (var packItem in sale.packItems) {
        await txn.insert('sale_packs', {
          'sale_id': saleId,
          'pack_id': packItem.packId,
          'quantity': packItem.quantity,
          'historical_price': packItem.historicalPrice,
        });

        await txn.rawUpdate('UPDATE packs SET units = units - ? WHERE id = ?', [
          packItem.quantity,
          packItem.packId,
        ]);
      }
    });
  }

  Future<List<Sale>> getSales() async {
    final database = await db;
    final salesMaps = await database.query('sales', orderBy: 'date DESC');

    List<Sale> salesList = [];

    for (var saleMap in salesMaps) {
      final saleId = saleMap['id'] as int;

      // Cargar productos de la venta
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

      // Cargar packs de la venta
      final packItemsMaps = await database.rawQuery(
        '''
        SELECT sp.*, p.name as pack_name 
        FROM sale_packs sp 
        LEFT JOIN packs p ON sp.pack_id = p.id 
        WHERE sp.sale_id = ?
      ''',
        [saleId],
      );

      List<SalePackItem> packItemsList = packItemsMaps
          .map(
            (pMap) => SalePackItem(
              id: pMap['id'] as int?,
              saleId: pMap['sale_id'] as int,
              packId: pMap['pack_id'] as int,
              packName:
                  pMap['pack_name'] as String? ?? 'Pack Eliminado/Desconocido',
              quantity: pMap['quantity'] as int,
              historicalPrice: (pMap['historical_price'] as num).toDouble(),
            ),
          )
          .toList();

      salesList.add(
        Sale(
          id: saleId,
          date: DateTime.parse(saleMap['date'] as String),
          totalAmount: (saleMap['total_amount'] as num).toDouble(),
          fairName: saleMap['fair_name'] as String?,
          items: itemsList,
          packItems: packItemsList,
        ),
      );
    }

    return salesList;
  }

  Future<void> refundSale(Sale sale) async {
    final database = await db;

    await database.transaction((txn) async {
      // 1. Restaurar stock de productos individuales
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
            {'units': restoredUnits, 'is_active': 1},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }

      // 2. Restaurar unidades de packs vendidos
      for (var packItem in sale.packItems) {
        final List<Map<String, dynamic>> maps = await txn.query(
          'packs',
          columns: ['units'],
          where: 'id = ?',
          whereArgs: [packItem.packId],
        );

        if (maps.isNotEmpty) {
          final currentUnits = maps.first['units'] as int;
          final restoredUnits = currentUnits + packItem.quantity;

          await txn.update(
            'packs',
            {'units': restoredUnits},
            where: 'id = ?',
            whereArgs: [packItem.packId],
          );
        }
      }

      // 3. Eliminar registros de la venta
      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );
      await txn.delete(
        'sale_packs',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );
      await txn.delete('sales', where: 'id = ?', whereArgs: [sale.id]);
    });
  }

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

  Future<List<String>> getAvailableFairs() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.rawQuery(
      'SELECT DISTINCT fair_name FROM sales WHERE fair_name IS NOT NULL AND fair_name != ""',
    );
    return maps.map((m) => m['fair_name'] as String).toList();
  }

  // ==========================================
  // --- MÉTRICAS Y DASHBOARD ---
  // ==========================================
  Future<double> getTotalRevenue() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(total_amount) as total FROM sales',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getInventoryCost() async {
    final database = await db;
    // Coste de productos en almacén + coste de piezas invertidas en packs montados
    final prodCostResult = await database.rawQuery(
      'SELECT SUM(cost * units) as total FROM products',
    );
    final double productsCost =
        (prodCostResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final packCostResult = await database.rawQuery('''
      SELECT SUM(p.cost * pi.quantity * pk.units) as total 
      FROM packs pk
      JOIN pack_items pi ON pk.id = pi.pack_id
      JOIN products p ON pi.product_id = p.id
    ''');
    final double packsCost =
        (packCostResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return productsCost + packsCost;
  }

  Future<double> getExpectedRevenue() async {
    final database = await db;
    // Ingreso esperado de productos + ingreso esperado de packs
    final prodRevenueResult = await database.rawQuery(
      'SELECT SUM(price * units) as total FROM products',
    );
    final double productsRevenue =
        (prodRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final packRevenueResult = await database.rawQuery(
      'SELECT SUM(price * units) as total FROM packs',
    );
    final double packsRevenue =
        (packRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return productsRevenue + packsRevenue;
  }

  Future<double> getActualNetProfit() async {
    final database = await db;
    // Beneficio de productos sueltos
    final prodProfitResult = await database.rawQuery('''
      SELECT SUM((si.historical_price - COALESCE(p.cost, 0)) * si.quantity) as net_profit 
      FROM sale_items si 
      LEFT JOIN products p ON si.product_id = p.id
    ''');
    final double prodProfit =
        (prodProfitResult.first['net_profit'] as num?)?.toDouble() ?? 0.0;

    // Beneficio de packs vendidos (precio venta del pack - coste de sus componentes)
    final packProfitResult = await database.rawQuery('''
      SELECT SUM(
        sp.quantity * (
          sp.historical_price - COALESCE((
            SELECT SUM(p.cost * pi.quantity)
            FROM pack_items pi
            JOIN products p ON pi.product_id = p.id
            WHERE pi.pack_id = sp.pack_id
          ), 0)
        )
      ) as net_profit
      FROM sale_packs sp
    ''');
    final double packProfit =
        (packProfitResult.first['net_profit'] as num?)?.toDouble() ?? 0.0;

    return prodProfit + packProfit;
  }

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

  Future<Map<String, double>> getDailyNetProfits() async {
    final database = await db;
    final sales = await getSales();
    Map<String, double> netProfits = {};

    for (var sale in sales) {
      final key = sale.fairName ?? sale.date.toIso8601String().substring(0, 10);

      // Calcular beneficio neto de esta venta (productos + packs)
      double saleProfit = 0.0;

      for (var item in sale.items) {
        final prod = await getProductById(item.productId);
        final cost = prod?.cost ?? 0.0;
        saleProfit += (item.historicalPrice - cost) * item.quantity;
      }

      for (var packItem in sale.packItems) {
        // Calcular coste de los componentes del pack
        final itemsResult = await database.rawQuery(
          '''
          SELECT SUM(p.cost * pi.quantity) as pack_unit_cost
          FROM pack_items pi
          JOIN products p ON pi.product_id = p.id
          WHERE pi.pack_id = ?
        ''',
          [packItem.packId],
        );

        final double packUnitCost =
            (itemsResult.first['pack_unit_cost'] as num?)?.toDouble() ?? 0.0;
        saleProfit +=
            (packItem.historicalPrice - packUnitCost) * packItem.quantity;
      }

      netProfits[key] = (netProfits[key] ?? 0.0) + saleProfit;
    }

    return netProfits;
  }

  // ==========================================
  // --- PROMOCIONES ---
  // ==========================================
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
