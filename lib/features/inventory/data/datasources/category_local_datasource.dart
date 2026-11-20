import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../history/data/history_recorder.dart';
import '../../../history/domain/change_entry.dart';
import '../../domain/product_category.dart';

class CategoryLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  Future<List<ProductCategory>> getCategories() async {
    final database = await db;
    final rows = await database.query(
      'categories',
      orderBy: 'name COLLATE NOCASE',
    );
    return [
      for (final r in rows)
        ProductCategory(id: r['id'] as int, name: r['name'] as String),
    ];
  }

  Future<ProductCategory> getOrCreate(String name) async {
    final database = await db;
    final clean = name.trim();
    return database.transaction((txn) async {
      var rows = await txn.query(
        'categories',
        where: 'name = ?',
        whereArgs: [clean],
        limit: 1,
      );
      if (rows.isEmpty) {
        final id = await txn.insert('categories', {
          'name': clean,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        rows = await txn.query(
          'categories',
          where: 'name = ?',
          whereArgs: [clean],
          limit: 1,
        );
        // Solo se anota si de verdad se ha creado ahora
        if (id > 0) {
          await HistoryRecorder.recordCreated(txn, ChangeEntity.category, id);
        }
      }
      return ProductCategory(
        id: rows.first['id'] as int,
        name: rows.first['name'] as String,
      );
    });
  }

  Future<void> delete(int id) async {
    final database = await db;
    await database.transaction((txn) async {
      // Lo que cambia al borrar: la categoría, los productos que la tenían y
      // los combos con un hueco por esa categoría. Todo queda en un grupo.
      final categoryBefore = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.category,
        id,
      );
      final productRows = await txn.query(
        'products',
        columns: ['id'],
        where: 'category_id = ? AND is_active = 1',
        whereArgs: [id],
      );
      final productIds = [for (final r in productRows) r['id'] as int];
      final productsBefore = {
        for (final productId in productIds)
          productId: await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.product,
            productId,
          ),
      };
      final comboRows = await txn.rawQuery(
        'SELECT DISTINCT combo_id FROM combo_slots WHERE category_id = ?',
        [id],
      );
      final comboIds = [for (final r in comboRows) r['combo_id'] as int];
      final combosBefore = {
        for (final comboId in comboIds)
          comboId: await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.combo,
            comboId,
          ),
      };

      // Por si las claves foráneas no se aplicaran (BD migradas)
      await txn.update(
        'products',
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'combo_slots',
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);

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
      for (final comboId in comboIds) {
        await HistoryRecorder.recordUpdated(
          txn,
          ChangeEntity.combo,
          comboId,
          before: combosBefore[comboId],
          groupId: group,
        );
      }
      await HistoryRecorder.recordDeleted(
        txn,
        ChangeEntity.category,
        id,
        before: categoryBefore,
        groupId: group,
      );
    });
  }

  /// Cambia el nombre. Devuelve false si ya existe otra con ese nombre.
  Future<bool> rename(int id, String name) async {
    final database = await db;
    final clean = name.trim();
    final clash = await database.query(
      'categories',
      where: 'name = ? AND id != ?',
      whereArgs: [clean, id],
      limit: 1,
    );
    if (clash.isNotEmpty) return false;
    await database.transaction((txn) async {
      final before = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.category,
        id,
      );
      await txn.update(
        'categories',
        {'name': clean},
        where: 'id = ?',
        whereArgs: [id],
      );
      await HistoryRecorder.recordUpdated(
        txn,
        ChangeEntity.category,
        id,
        before: before,
      );
    });
    return true;
  }

  /// Nº de productos activos de cada categoría.
  Future<Map<int, int>> countAll() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT category_id, COUNT(*) AS n FROM products '
      'WHERE is_active = 1 AND category_id IS NOT NULL GROUP BY category_id',
    );
    return {for (final r in rows) r['category_id'] as int: r['n'] as int};
  }

  /// Mete [add] en la categoría y saca [remove] (quedan sin categoría).
  Future<void> setProducts(
    int id, {
    required Set<int> add,
    required Set<int> remove,
  }) async {
    final database = await db;
    await database.transaction((txn) async {
      final group = HistoryRecorder.newGroupId();
      for (final productId in add) {
        final before = await HistoryRecorder.snapshot(
          txn,
          ChangeEntity.product,
          productId,
        );
        await txn.update(
          'products',
          {'category_id': id},
          where: 'id = ?',
          whereArgs: [productId],
        );
        await HistoryRecorder.recordUpdated(
          txn,
          ChangeEntity.product,
          productId,
          before: before,
          groupId: group,
        );
      }
      for (final productId in remove) {
        final before = await HistoryRecorder.snapshot(
          txn,
          ChangeEntity.product,
          productId,
        );
        await txn.update(
          'products',
          {'category_id': null},
          where: 'id = ? AND category_id = ?',
          whereArgs: [productId, id],
        );
        await HistoryRecorder.recordUpdated(
          txn,
          ChangeEntity.product,
          productId,
          before: before,
          groupId: group,
        );
      }
    });
  }

  Future<int> countProducts(int id) async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS n FROM products WHERE category_id = ? AND is_active = 1',
      [id],
    );
    return (rows.first['n'] as int?) ?? 0;
  }
}
