import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

class DashboardLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  Future<double> getTotalRevenue() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(total_amount) as total FROM sales',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getInventoryCost() async {
    final database = await db;
    // Coste de productos sueltos
    final prodCostResult = await database.rawQuery(
      'SELECT SUM(cost * units) as total FROM products',
    );

    // Coste de los productos invertidos dentro de los packs montados
    final packCostResult = await database.rawQuery('''
      SELECT SUM(p.cost * pi.quantity * pk.units) as total 
      FROM packs pk
      JOIN pack_items pi ON pk.id = pi.pack_id
      JOIN products p ON pi.product_id = p.id
    ''');

    final double productsCost =
        (prodCostResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final double packsCost =
        (packCostResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return productsCost + packsCost;
  }

  Future<double> getExpectedRevenue() async {
    final database = await db;
    final prodResult = await database.rawQuery(
      'SELECT SUM(price * units) as total FROM products',
    );
    final packResult = await database.rawQuery(
      'SELECT SUM(price * units) as total FROM packs',
    );

    return ((prodResult.first['total'] as num?)?.toDouble() ?? 0.0) +
        ((packResult.first['total'] as num?)?.toDouble() ?? 0.0);
  }

  Future<double> getActualNetProfit() async {
    final database = await db;
    final prodProfitResult = await database.rawQuery('''
      SELECT SUM((si.historical_price - COALESCE(p.cost, 0)) * si.quantity) as net_profit 
      FROM sale_items si 
      LEFT JOIN products p ON si.product_id = p.id
    ''');

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

    return ((prodProfitResult.first['net_profit'] as num?)?.toDouble() ?? 0.0) +
        ((packProfitResult.first['net_profit'] as num?)?.toDouble() ?? 0.0);
  }

  Future<Map<String, double>> getDailySales() async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT COALESCE(fair_name, date(date)) as group_key, SUM(total_amount) as total 
      FROM sales 
      GROUP BY group_key 
      ORDER BY date ASC
    ''');

    return {
      for (var row in result)
        row['group_key'] as String: (row['total'] as num).toDouble(),
    };
  }

  // CÁLCULO OPTIMIZADO (Cruza datos en memoria para evitar el problema N+1)
  Future<Map<String, double>> getDailyNetProfits() async {
    final database = await db;
    Map<String, double> netProfits = {};

    // 1. Precargar costes de productos
    final prodMaps = await database.query('products', columns: ['id', 'cost']);
    final productCosts = {
      for (var p in prodMaps) p['id'] as int: (p['cost'] as num).toDouble(),
    };

    // 2. Precargar costes de fabricación de los packs
    final packCostResult = await database.rawQuery('''
      SELECT pi.pack_id, SUM(p.cost * pi.quantity) as pack_unit_cost
      FROM pack_items pi 
      JOIN products p ON pi.product_id = p.id 
      GROUP BY pi.pack_id
    ''');
    final packCosts = {
      for (var p in packCostResult)
        p['pack_id'] as int: (p['pack_unit_cost'] as num?)?.toDouble() ?? 0.0,
    };

    // 3. Iterar ventas y calcular cruces rápidos en memoria
    final salesMaps = await database.query('sales', orderBy: 'date ASC');
    for (var saleMap in salesMaps) {
      final saleId = saleMap['id'] as int;
      final key =
          (saleMap['fair_name'] as String?) ??
          (saleMap['date'] as String).substring(0, 10);
      double saleProfit = 0.0;

      // Beneficios de items sueltos
      final itemsMaps = await database.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      for (var item in itemsMaps) {
        final cost = productCosts[item['product_id'] as int] ?? 0.0;
        saleProfit +=
            ((item['historical_price'] as num).toDouble() - cost) *
            (item['quantity'] as int);
      }

      // Beneficios de packs
      final packsMaps = await database.query(
        'sale_packs',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      for (var pack in packsMaps) {
        final cost = packCosts[pack['pack_id'] as int] ?? 0.0;
        saleProfit +=
            ((pack['historical_price'] as num).toDouble() - cost) *
            (pack['quantity'] as int);
      }

      netProfits[key] = (netProfits[key] ?? 0.0) + saleProfit;
    }
    return netProfits;
  }
}
