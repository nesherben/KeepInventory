import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../history/data/history_recorder.dart';
import '../../../history/domain/change_entry.dart';
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
    return database.transaction((txn) async {
      final id = await txn.insert('products', product.toMap());
      await HistoryRecorder.recordCreated(txn, ChangeEntity.product, id);
      return id;
    });
  }

  Future<int> updateProduct(ProductModel product) async {
    final database = await db;
    final id = product.id;
    if (id == null) {
      return database.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }
    return database.transaction((txn) async {
      final before = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.product,
        id,
      );
      final changed = await txn.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      // Solo se registra lo de configuración: el stock no cuenta
      await HistoryRecorder.recordUpdated(
        txn,
        ChangeEntity.product,
        id,
        before: before,
      );
      return changed;
    });
  }

  /// Actualiza solo las columnas indicadas (no pisa el resto del producto).
  Future<int> updateFields(int id, Map<String, Object?> values) async {
    if (values.isEmpty) return 0;
    final database = await db;
    return database.transaction((txn) async {
      final before = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.product,
        id,
      );
      final changed = await txn.update(
        'products',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      await HistoryRecorder.recordUpdated(
        txn,
        ChangeEntity.product,
        id,
        before: before,
      );
      return changed;
    });
  }

  /// Asigna [promotionId] a todos los productos activos de la categoría.
  /// Devuelve cuántos se han cambiado.
  Future<int> setPromotionForCategory(int categoryId, int promotionId) async {
    final database = await db;
    return database.transaction((txn) async {
      final rows = await txn.query(
        'products',
        columns: ['id'],
        where: 'category_id = ? AND is_active = 1',
        whereArgs: [categoryId],
      );
      final ids = [for (final r in rows) r['id'] as int];
      final before = {
        for (final id in ids)
          id: await HistoryRecorder.snapshot(txn, ChangeEntity.product, id),
      };
      final changed = await txn.update(
        'products',
        {'promotion_id': promotionId},
        where: 'category_id = ? AND is_active = 1',
        whereArgs: [categoryId],
      );
      // Una operación, varias entradas: comparten grupo
      final group = HistoryRecorder.newGroupId();
      for (final id in ids) {
        await HistoryRecorder.recordUpdated(
          txn,
          ChangeEntity.product,
          id,
          before: before[id],
          groupId: group,
        );
      }
      return changed;
    });
  }

  /// Cambia varios productos a la vez (columnas por id) en UNA transacción:
  /// o se aplican todos o ninguno. Cada uno queda anotado en el historial y
  /// comparten grupo. Devuelve cuántos se cambiaron.
  Future<int> updateMany(Map<int, Map<String, Object?>> valuesById) async {
    final database = await db;
    return database.transaction((txn) async {
      final group = HistoryRecorder.newGroupId();
      var count = 0;
      for (final entry in valuesById.entries) {
        if (entry.value.isEmpty) continue;
        final before = await HistoryRecorder.snapshot(
          txn,
          ChangeEntity.product,
          entry.key,
        );
        final changed = await txn.update(
          'products',
          entry.value,
          where: 'id = ?',
          whereArgs: [entry.key],
        );
        count += changed;
        await HistoryRecorder.recordUpdated(
          txn,
          ChangeEntity.product,
          entry.key,
          before: before,
          groupId: group,
        );
      }
      return count;
    });
  }

  /// Borrado lógico de varios productos en una transacción (mismo grupo en el
  /// historial). Devuelve cuántos se borraron.
  Future<int> deleteMany(List<int> ids) async {
    final database = await db;
    return database.transaction((txn) async {
      final group = HistoryRecorder.newGroupId();
      var count = 0;
      for (final id in ids) {
        final before = await HistoryRecorder.snapshot(
          txn,
          ChangeEntity.product,
          id,
        );
        count += await txn.update(
          'products',
          {'is_active': 0, 'units': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
        await HistoryRecorder.recordDeleted(
          txn,
          ChangeEntity.product,
          id,
          before: before,
          groupId: group,
        );
      }
      return count;
    });
  }

  /// Suma (o resta) unidades en una sola operación, sin bajar de 0.
  /// El stock no se registra en el historial.
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
    return database.transaction((txn) async {
      final before = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.product,
        id,
      );
      // Borrado lógico para no romper el historial de tickets antiguos
      final changed = await txn.update(
        'products',
        {'is_active': 0, 'units': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      await HistoryRecorder.recordDeleted(
        txn,
        ChangeEntity.product,
        id,
        before: before,
      );
      return changed;
    });
  }
}
