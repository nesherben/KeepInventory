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

  Future<Map<String, double>> getDailyNetProfits() async {
    final database = await db;
    final result = await database.rawQuery('''
      WITH pack_costs AS (
        SELECT pi.pack_id, SUM(p.cost * pi.quantity) AS unit_cost
        FROM pack_items pi
        JOIN products p ON p.id = pi.product_id
        GROUP BY pi.pack_id
      ), sale_profits AS (
        SELECT s.fair_name, date(s.date) AS sale_date,
          (si.historical_price - COALESCE(p.cost, 0)) * si.quantity AS profit
        FROM sales s
        JOIN sale_items si ON si.sale_id = s.id
        LEFT JOIN products p ON p.id = si.product_id
        UNION ALL
        SELECT s.fair_name, date(s.date) AS sale_date,
          (sp.historical_price - COALESCE(pc.unit_cost, 0)) * sp.quantity AS profit
        FROM sales s
        JOIN sale_packs sp ON sp.sale_id = s.id
        LEFT JOIN pack_costs pc ON pc.pack_id = sp.pack_id
      )
      SELECT COALESCE(fair_name, sale_date) AS group_key, SUM(profit) AS total
      FROM sale_profits
      GROUP BY group_key
    ''');

    return {
      for (final row in result)
        row['group_key'] as String: (row['total'] as num).toDouble(),
    };
  }
}
