import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/change_diff.dart';
import '../domain/change_entry.dart';

/// Registra en `change_log` los cambios de configuración (precio, nombre,
/// promoción, categoría, packs, combos…).
///
/// Se llama SIEMPRE dentro de la misma transacción que el cambio: o se guardan
/// los dos o ninguno. No registra cantidades (stock) ni ventas.
class HistoryRecorder {
  const HistoryRecorder._();

  /// Entradas que se conservan; al pasar el límite se borran las más antiguas.
  static const maxEntries = 500;

  /// Clave de la foto con los nombres de las referencias (no es un campo de
  /// configuración: no entra en las diferencias).
  static const labelsKey = '_labels';

  /// Identificador para agrupar las entradas de una misma operación.
  static String newGroupId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  /// Registra la creación de [id] (tras insertarlo).
  static Future<void> recordCreated(
    DatabaseExecutor txn,
    ChangeEntity entity,
    int id, {
    String? groupId,
    DateTime? now,
  }) async {
    final after = await snapshot(txn, entity, id);
    if (after == null) return;
    await _record(
      txn,
      entity,
      id,
      ChangeAction.create,
      before: null,
      after: after,
      groupId: groupId,
      now: now,
    );
  }

  /// Registra una edición de [id]. [before] es la [snapshot] tomada ANTES del
  /// cambio; la de después se toma aquí. Si no cambió ningún campo de
  /// configuración (p. ej. solo el stock) no se registra nada.
  static Future<void> recordUpdated(
    DatabaseExecutor txn,
    ChangeEntity entity,
    int id, {
    required Map<String, Object?>? before,
    String? groupId,
    DateTime? now,
  }) async {
    if (before == null) return;
    final after = await snapshot(txn, entity, id);
    if (after == null) return;
    await _record(
      txn,
      entity,
      id,
      ChangeAction.update,
      before: before,
      after: after,
      groupId: groupId,
      now: now,
    );
  }

  /// Registra el borrado de [id]. [before] es la [snapshot] de antes;
  /// [extraBefore] añade datos para poder rehacer el elemento (p. ej. los
  /// productos que tenía una categoría).
  static Future<void> recordDeleted(
    DatabaseExecutor txn,
    ChangeEntity entity,
    int id, {
    required Map<String, Object?>? before,
    Map<String, Object?> extraBefore = const {},
    String? groupId,
    DateTime? now,
  }) async {
    if (before == null) return;
    await _record(
      txn,
      entity,
      id,
      ChangeAction.delete,
      before: before,
      after: null,
      extraBefore: extraBefore,
      groupId: groupId,
      now: now,
    );
  }

  /// Foto de los campos de configuración de [id] (null si no existe o está
  /// borrado). El campo `image` lleva un hash de los bytes, solo para detectar
  /// cambios: los bytes no se guardan nunca.
  static Future<Map<String, Object?>?> snapshot(
    DatabaseExecutor txn,
    ChangeEntity entity,
    int id,
  ) {
    switch (entity) {
      case ChangeEntity.product:
        return _productSnapshot(txn, id);
      case ChangeEntity.category:
        return _categorySnapshot(txn, id);
      case ChangeEntity.promotion:
        return _promotionSnapshot(txn, id);
      case ChangeEntity.pack:
        return _packSnapshot(txn, id);
      case ChangeEntity.combo:
        return _comboSnapshot(txn, id);
    }
  }

  // ---------------------------------------------------------------------
  // Fotos por tipo de elemento
  // ---------------------------------------------------------------------

  static Object? _imageHash(Object? bytes) =>
      bytes is List<int> && bytes.isNotEmpty ? Object.hashAll(bytes) : null;

  static Future<Map<String, Object?>?> _productSnapshot(
    DatabaseExecutor txn,
    int id,
  ) async {
    final rows = await txn.query(
      'products',
      where: 'id = ? AND is_active = 1',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final categoryId = r['category_id'];
    final promotionId = r['promotion_id'];
    return {
      'name': r['name'],
      'price': r['price'],
      'cost': r['cost'],
      'category_id': categoryId,
      'promotion_id': promotionId,
      ChangeTracking.imageField: _imageHash(r['image_bytes']),
      // Nombres resueltos AHORA: si la categoría o la promoción se borra justo
      // después, la entrada sigue diciendo cómo se llamaba
      labelsKey: {
        'category': categoryId is int
            ? await _nameOf(txn, 'categories', categoryId)
            : null,
        'promotion': promotionId is int
            ? await _nameOf(txn, 'promotions', promotionId)
            : null,
      },
    };
  }

  static Future<Map<String, Object?>?> _categorySnapshot(
    DatabaseExecutor txn,
    int id,
  ) async {
    final rows = await txn.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return {'name': rows.first['name']};
  }

  static Future<Map<String, Object?>?> _promotionSnapshot(
    DatabaseExecutor txn,
    int id,
  ) async {
    final rows = await txn.query(
      'promotions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return {
      'name': r['name'],
      'type': r['type'],
      'threshold': r['threshold'],
      'discount_value': r['discount_value'],
    };
  }

  static Future<Map<String, Object?>?> _packSnapshot(
    DatabaseExecutor txn,
    int id,
  ) async {
    final rows = await txn.query(
      'packs',
      where: 'id = ? AND is_active = 1',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final items = await txn.rawQuery(
      '''
      SELECT pi.product_id, pi.quantity, p.name AS product_name
      FROM pack_items pi
      LEFT JOIN products p ON p.id = pi.product_id
      WHERE pi.pack_id = ?
      ORDER BY pi.product_id
    ''',
      [id],
    );
    return {
      'name': r['name'],
      'price': r['price'],
      'items': [
        for (final i in items)
          {
            'product_id': i['product_id'],
            'name': i['product_name'],
            'quantity': i['quantity'],
          },
      ],
      ChangeTracking.imageField: _imageHash(r['image_bytes']),
    };
  }

  static Future<Map<String, Object?>?> _comboSnapshot(
    DatabaseExecutor txn,
    int id,
  ) async {
    final rows = await txn.query(
      'combos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final slots = await txn.query(
      'combo_slots',
      where: 'combo_id = ?',
      whereArgs: [id],
      orderBy: 'position, id',
    );
    final slotList = <Map<String, Object?>>[];
    for (final slot in slots) {
      final products = await txn.query(
        'combo_slot_products',
        columns: ['product_id'],
        where: 'slot_id = ?',
        whereArgs: [slot['id']],
        orderBy: 'product_id',
      );
      slotList.add({
        'name': slot['name'],
        'quantity': slot['quantity'],
        'category_id': slot['category_id'],
        'product_ids': [for (final p in products) p['product_id']],
      });
    }
    return {
      'name': rows.first['name'],
      'price': rows.first['price'],
      'slots': slotList,
    };
  }

  // ---------------------------------------------------------------------
  // Escritura
  // ---------------------------------------------------------------------

  static Future<void> _record(
    DatabaseExecutor txn,
    ChangeEntity entity,
    int id,
    ChangeAction action, {
    required Map<String, Object?>? before,
    required Map<String, Object?>? after,
    Map<String, Object?> extraBefore = const {},
    String? groupId,
    DateTime? now,
  }) async {
    final diff = ChangeTracking.diff(entity, before: before, after: after);
    if (diff == null) return;

    final storedBefore = await _storable(
      txn,
      diff.before,
      before?[labelsKey] as Map<String, Object?>?,
    );
    final storedAfter = await _storable(
      txn,
      diff.after,
      after?[labelsKey] as Map<String, Object?>?,
    );
    if (extraBefore.isNotEmpty) storedBefore.addAll(extraBefore);

    final name = (after?['name'] ?? before?['name'] ?? '').toString();

    // Un cambio nuevo descarta lo que se podía rehacer
    await txn.delete('change_log', where: 'undone = 1');
    await txn.insert('change_log', {
      'created_at': (now ?? DateTime.now()).toIso8601String(),
      'entity': entity.dbValue,
      'entity_id': id,
      'entity_name': name,
      'action': action.dbValue,
      'changed_fields': jsonEncode(diff.changedFields),
      'before_json': jsonEncode(storedBefore),
      'after_json': jsonEncode(storedAfter),
      'undone': 0,
      'group_id': groupId,
    });
    await _prune(txn);
  }

  /// Deja solo las [maxEntries] entradas más recientes.
  static Future<void> _prune(DatabaseExecutor txn) async {
    await txn.rawDelete(
      '''
      DELETE FROM change_log WHERE id NOT IN (
        SELECT id FROM change_log ORDER BY created_at DESC, id DESC LIMIT ?
      )
    ''',
      [maxEntries],
    );
  }

  /// Valores listos para guardar: la imagen pasa a "hay / no hay" (nunca se
  /// guardan bytes) y los ids de categoría y promoción llevan su nombre.
  static Future<Map<String, Object?>> _storable(
    DatabaseExecutor txn,
    Map<String, Object?> values,
    Map<String, Object?>? labels,
  ) async {
    final result = <String, Object?>{};
    for (final entry in values.entries) {
      result[entry.key] = entry.key == ChangeTracking.imageField
          ? entry.value != null
          : entry.value;
    }
    final categoryId = values['category_id'];
    if (categoryId is int) {
      result['category'] =
          labels?['category'] ?? await _nameOf(txn, 'categories', categoryId);
    }
    final promotionId = values['promotion_id'];
    if (promotionId is int) {
      result['promotion'] =
          labels?['promotion'] ?? await _nameOf(txn, 'promotions', promotionId);
    }
    return result;
  }

  static Future<String?> _nameOf(
    DatabaseExecutor txn,
    String table,
    int id,
  ) async {
    final rows = await txn.query(
      table,
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['name'] as String?;
  }
}
