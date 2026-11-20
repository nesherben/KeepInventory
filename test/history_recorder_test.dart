import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_schema_creator.dart';
import 'package:keepinventory/features/history/data/history_recorder.dart';
import 'package:keepinventory/features/history/domain/change_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        singleInstance: false,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: (d, _) =>
            DatabaseSchemaCreator.create(execute: (sql) => d.execute(sql)),
        version: 1,
      ),
    );
  });

  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> log() =>
      db.query('change_log', orderBy: 'id');

  Future<int> insertProduct({
    String name = 'Camiseta',
    double price = 10,
    int units = 5,
    int? categoryId,
    int? promotionId,
    Uint8List? image,
  }) async {
    return db.transaction((txn) async {
      final id = await txn.insert('products', {
        'name': name,
        'units': units,
        'price': price,
        'cost': 4.0,
        'category_id': categoryId,
        'promotion_id': promotionId,
        'image_bytes': image,
      });
      await HistoryRecorder.recordCreated(txn, ChangeEntity.product, id);
      return id;
    });
  }

  Future<void> updateProduct(int id, Map<String, Object?> values) async {
    await db.transaction((txn) async {
      final before = await HistoryRecorder.snapshot(
        txn,
        ChangeEntity.product,
        id,
      );
      await txn.update('products', values, where: 'id = ?', whereArgs: [id]);
      await HistoryRecorder.recordUpdated(
        txn,
        ChangeEntity.product,
        id,
        before: before,
      );
    });
  }

  group('HistoryRecorder', () {
    test('records a creation with the new values', () async {
      final id = await insertProduct();

      final rows = await log();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row['entity'], 'product');
      expect(row['entity_id'], id);
      expect(row['entity_name'], 'Camiseta');
      expect(row['action'], 'create');
      expect(row['undone'], 0);
      final after = jsonDecode(row['after_json'] as String) as Map;
      expect(after['name'], 'Camiseta');
      expect(after['price'], 10);
      expect(jsonDecode(row['before_json'] as String), isEmpty);
    });

    test('records only the changed fields of an edit', () async {
      final id = await insertProduct();

      await updateProduct(id, {'price': 12.0});

      final row = (await log()).last;
      expect(row['action'], 'update');
      expect(jsonDecode(row['changed_fields'] as String), ['price']);
      expect(jsonDecode(row['before_json'] as String), {'price': 10});
      expect(jsonDecode(row['after_json'] as String), {'price': 12});
      expect(row['entity_name'], 'Camiseta');
    });

    test('stock changes are never recorded', () async {
      final id = await insertProduct();

      await updateProduct(id, {'units': 99});

      expect(await log(), hasLength(1)); // solo la creación
    });

    test('an edit that changes nothing records nothing', () async {
      final id = await insertProduct();

      await updateProduct(id, {'price': 10.0});

      expect(await log(), hasLength(1));
    });

    test('category and promotion changes keep a readable name', () async {
      final ropa = await db.insert('categories', {'name': 'Ropa'});
      final tazas = await db.insert('categories', {'name': 'Tazas'});
      final id = await insertProduct(categoryId: ropa);

      await updateProduct(id, {'category_id': tazas});

      final row = (await log()).last;
      final before = jsonDecode(row['before_json'] as String) as Map;
      final after = jsonDecode(row['after_json'] as String) as Map;
      expect(before['category_id'], ropa);
      expect(before['category'], 'Ropa');
      expect(after['category_id'], tazas);
      expect(after['category'], 'Tazas');

      // El nombre sigue en el historial aunque se borre la categoría
      await db.delete('categories', where: 'id = ?', whereArgs: [ropa]);
      final again = (await log()).last;
      expect(
        (jsonDecode(again['before_json'] as String) as Map)['category'],
        'Ropa',
      );
    });

    test(
      'names survive when the category is deleted before recording',
      () async {
        final ropa = await db.insert('categories', {'name': 'Ropa'});
        final id = await insertProduct(categoryId: ropa);

        // Igual que al borrar una categoría: foto, borrado y luego se anota
        await db.transaction((txn) async {
          final before = await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.product,
            id,
          );
          await txn.update(
            'products',
            {'category_id': null},
            where: 'id = ?',
            whereArgs: [id],
          );
          await txn.delete('categories', where: 'id = ?', whereArgs: [ropa]);
          await HistoryRecorder.recordUpdated(
            txn,
            ChangeEntity.product,
            id,
            before: before,
          );
        });

        final row = (await log()).last;
        final before = jsonDecode(row['before_json'] as String) as Map;
        expect(before['category_id'], ropa);
        expect(before['category'], 'Ropa');
      },
    );

    test('images are recorded as a flag, never as bytes', () async {
      final id = await insertProduct();

      await updateProduct(id, {
        'image_bytes': Uint8List.fromList(List.filled(2000, 7)),
      });

      final row = (await log()).last;
      expect(jsonDecode(row['changed_fields'] as String), ['image']);
      expect(jsonDecode(row['before_json'] as String), {'image': false});
      expect(jsonDecode(row['after_json'] as String), {'image': true});
      // Nada pesado en la fila
      expect((row['after_json'] as String).length, lessThan(40));
    });

    test(
      'a soft delete is recorded as a deletion with the old values',
      () async {
        final id = await insertProduct();

        await db.transaction((txn) async {
          final before = await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.product,
            id,
          );
          await txn.update(
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
        });

        final row = (await log()).last;
        expect(row['action'], 'delete');
        expect(
          (jsonDecode(row['before_json'] as String) as Map)['name'],
          'Camiseta',
        );
        expect(jsonDecode(row['after_json'] as String), isEmpty);
        // Un producto ya borrado no tiene foto de configuración
        await db.transaction((txn) async {
          expect(
            await HistoryRecorder.snapshot(txn, ChangeEntity.product, id),
            isNull,
          );
        });
      },
    );

    test(
      'pack snapshots include readable components and track changes',
      () async {
        final shirt = await insertProduct();
        final mug = await insertProduct(name: 'Taza', price: 5.99);
        late int packId;
        await db.transaction((txn) async {
          packId = await txn.insert('packs', {
            'name': 'Pack',
            'price': 15.0,
            'units': 1,
          });
          await txn.insert('pack_items', {
            'pack_id': packId,
            'product_id': shirt,
            'quantity': 1,
          });
          await HistoryRecorder.recordCreated(txn, ChangeEntity.pack, packId);
        });
        await db.transaction((txn) async {
          final before = await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.pack,
            packId,
          );
          await txn.insert('pack_items', {
            'pack_id': packId,
            'product_id': mug,
            'quantity': 1,
          });
          await HistoryRecorder.recordUpdated(
            txn,
            ChangeEntity.pack,
            packId,
            before: before,
          );
        });

        final rows = await log();
        final created = rows.firstWhere((r) => r['entity'] == 'pack');
        final items =
            (jsonDecode(created['after_json'] as String) as Map)['items']
                as List;
        expect(items.single['name'], 'Camiseta');

        final updated = rows.last;
        expect(updated['entity'], 'pack');
        expect(jsonDecode(updated['changed_fields'] as String), ['items']);
        expect(
          ((jsonDecode(updated['after_json'] as String) as Map)['items']
                  as List)
              .length,
          2,
        );
      },
    );

    test('combo snapshots track slots', () async {
      final shirt = await insertProduct();
      late int comboId;
      await db.transaction((txn) async {
        comboId = await txn.insert('combos', {'name': 'Duo', 'price': 10.0});
        final slot = await txn.insert('combo_slots', {
          'combo_id': comboId,
          'name': 'Prenda',
          'quantity': 1,
          'position': 0,
        });
        await txn.insert('combo_slot_products', {
          'slot_id': slot,
          'product_id': shirt,
        });
        await HistoryRecorder.recordCreated(txn, ChangeEntity.combo, comboId);
      });

      final row = (await log()).firstWhere((r) => r['entity'] == 'combo');
      final slots =
          (jsonDecode(row['after_json'] as String) as Map)['slots'] as List;
      expect(slots.single['name'], 'Prenda');
      expect(slots.single['product_ids'], [shirt]);
    });

    test('a new change discards what could be redone', () async {
      final id = await insertProduct();
      await updateProduct(id, {'price': 12.0});
      // Se deshace el último cambio (lo hará la fase 3): queda "rehacible"
      await db.update('change_log', {
        'undone': 1,
      }, where: 'id = (SELECT MAX(id) FROM change_log)');
      expect(await log(), hasLength(2));

      await updateProduct(id, {'price': 15.0});

      final rows = await log();
      expect(rows, hasLength(2)); // creación + el nuevo cambio
      expect(rows.every((r) => r['undone'] == 0), isTrue);
      expect(jsonDecode(rows.last['after_json'] as String), {'price': 15});
    });

    test(
      'keeps only the newest ${HistoryRecorder.maxEntries} entries',
      () async {
        final id = await insertProduct();
        for (var i = 1; i <= HistoryRecorder.maxEntries + 20; i++) {
          await updateProduct(id, {'price': 10.0 + i});
        }

        final rows = await log();
        expect(rows, hasLength(HistoryRecorder.maxEntries));
        // Se conservan las más recientes: la creación ya se podó
        expect(rows.any((r) => r['action'] == 'create'), isFalse);
        expect(
          (jsonDecode(rows.last['after_json'] as String) as Map)['price'],
          10 + HistoryRecorder.maxEntries + 20,
        );
      },
    );

    test('entries of one operation share a group id', () async {
      final ropa = await db.insert('categories', {'name': 'Ropa'});
      final a = await insertProduct(name: 'A', categoryId: ropa);
      final b = await insertProduct(name: 'B', categoryId: ropa);
      final promo = await db.insert('promotions', {
        'name': '10 %',
        'type': 'percentage',
        'threshold': 2,
        'discount_value': 10.0,
      });

      final group = HistoryRecorder.newGroupId();
      await db.transaction((txn) async {
        for (final id in [a, b]) {
          final before = await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.product,
            id,
          );
          await txn.update(
            'products',
            {'promotion_id': promo},
            where: 'id = ?',
            whereArgs: [id],
          );
          await HistoryRecorder.recordUpdated(
            txn,
            ChangeEntity.product,
            id,
            before: before,
            groupId: group,
          );
        }
      });

      final grouped = (await log()).where((r) => r['group_id'] == group);
      expect(grouped, hasLength(2));
      expect(
        (jsonDecode(grouped.first['after_json'] as String) as Map)['promotion'],
        '10 %',
      );
    });

    test('the change and its entry are saved atomically', () async {
      final id = await insertProduct();

      await expectLater(
        db.transaction((txn) async {
          final before = await HistoryRecorder.snapshot(
            txn,
            ChangeEntity.product,
            id,
          );
          await txn.update(
            'products',
            {'price': 99.0},
            where: 'id = ?',
            whereArgs: [id],
          );
          await HistoryRecorder.recordUpdated(
            txn,
            ChangeEntity.product,
            id,
            before: before,
          );
          throw StateError('falla a mitad');
        }),
        throwsStateError,
      );

      // Ni el cambio ni su entrada
      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(product.single['price'], 10);
      expect(await log(), hasLength(1));
    });
  });
}
