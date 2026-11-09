import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/combo.dart';

class ComboLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  Future<List<Combo>> getCombos() async {
    final database = await db;
    final comboRows = await database.query('combos', orderBy: 'id');
    final slotRows = await database.query(
      'combo_slots',
      orderBy: 'combo_id, position, id',
    );
    // Los productos borrados (borrado lógico) no cuentan para el combo
    final productRows = await database.rawQuery('''
      SELECT csp.slot_id, csp.product_id
      FROM combo_slot_products csp
      JOIN products p ON p.id = csp.product_id
      WHERE p.is_active = 1
    ''');

    final productsBySlot = <int, List<int>>{};
    for (final row in productRows) {
      productsBySlot
          .putIfAbsent(row['slot_id'] as int, () => [])
          .add(row['product_id'] as int);
    }
    final slotsByCombo = <int, List<ComboSlot>>{};
    for (final row in slotRows) {
      final slotId = row['id'] as int;
      slotsByCombo
          .putIfAbsent(row['combo_id'] as int, () => [])
          .add(
            ComboSlot(
              id: slotId,
              name: row['name'] as String,
              quantity: row['quantity'] as int,
              productIds: productsBySlot[slotId] ?? const [],
            ),
          );
    }

    return [
      for (final row in comboRows)
        Combo(
          id: row['id'] as int,
          name: row['name'] as String,
          price: (row['price'] as num).toDouble(),
          slots: slotsByCombo[row['id']] ?? const [],
        ),
    ];
  }

  /// Inserta o actualiza (los huecos se reescriben enteros).
  Future<int> saveCombo(Combo combo) async {
    final database = await db;
    return database.transaction((txn) async {
      final values = {'name': combo.name, 'price': combo.price};
      int comboId;
      if (combo.id == null) {
        comboId = await txn.insert('combos', values);
      } else {
        comboId = combo.id!;
        await txn.update(
          'combos',
          values,
          where: 'id = ?',
          whereArgs: [comboId],
        );
        await txn.delete(
          'combo_slots',
          where: 'combo_id = ?',
          whereArgs: [comboId],
        );
      }

      for (var i = 0; i < combo.slots.length; i++) {
        final slot = combo.slots[i];
        final slotId = await txn.insert('combo_slots', {
          'combo_id': comboId,
          'name': slot.name,
          'quantity': slot.quantity,
          'position': i,
        });
        for (final productId in slot.productIds.toSet()) {
          await txn.insert('combo_slot_products', {
            'slot_id': slotId,
            'product_id': productId,
          });
        }
      }
      return comboId;
    });
  }

  /// Las ventas no se ven afectadas: guardan su propia copia del combo.
  Future<void> deleteCombo(int id) async {
    final database = await db;
    await database.delete('combos', where: 'id = ?', whereArgs: [id]);
  }
}
