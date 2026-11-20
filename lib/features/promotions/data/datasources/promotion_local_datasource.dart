import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../history/data/history_recorder.dart';
import '../../../history/domain/change_entry.dart';
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
    return database.transaction((txn) async {
      final id = await txn.insert('promotions', promotion.toMap());
      await HistoryRecorder.recordCreated(txn, ChangeEntity.promotion, id);
      return id;
    });
  }

  Future<int> updatePromotion(PromotionModel promotion) async {
    final database = await db;
    final id = promotion.id;
    if (id == null) {
      return database.update(
        'promotions',
        promotion.toMap(),
        where: 'id = ?',
        whereArgs: [promotion.id],
      );
    }
    return database.transaction((txn) async {
      final before = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.promotion,
        id,
      );
      final changed = await txn.update(
        'promotions',
        promotion.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await HistoryRecorder.recordUpdated(
        txn,
        ChangeEntity.promotion,
        id,
        before: before,
      );
      return changed;
    });
  }

  Future<int> deletePromotion(int id) async {
    final database = await db;
    return database.transaction((txn) async {
      final before = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.promotion,
        id,
      );
      // Los productos que la tenían se quedan sin promoción (ON DELETE SET
      // NULL): cada uno queda anotado en el mismo grupo que el borrado
      final rows = await txn.query(
        'products',
        columns: ['id'],
        where: 'promotion_id = ? AND is_active = 1',
        whereArgs: [id],
      );
      final productIds = [for (final r in rows) r['id'] as int];
      final productsBefore = {
        for (final productId in productIds)
          productId: await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.product,
            productId,
          ),
      };

      final deleted = await txn.delete(
        'promotions',
        where: 'id = ?',
        whereArgs: [id],
      );
      // Por si las claves foráneas no se aplicaran
      await txn.update(
        'products',
        {'promotion_id': null},
        where: 'promotion_id = ?',
        whereArgs: [id],
      );

      final group = HistoryRecorder.newGroupId();
      for (final productId in productIds) {
        await HistoryRecorder.recordUpdated(
          txn,
          ChangeEntity.product,
          productId,
          before: productsBefore[productId],
          groupId: group,
        );
      }
      await HistoryRecorder.recordDeleted(
        txn,
        ChangeEntity.promotion,
        id,
        before: before,
        groupId: group,
      );
      return deleted;
    });
  }
}
