import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../promotion_model.dart';

class PromotionLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

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
