import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/pack.dart'; // Importamos para la clase PackItem (asumiendo que está ahí)

class PackLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

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
}
