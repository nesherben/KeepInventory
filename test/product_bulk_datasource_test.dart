import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_helper.dart';
import 'package:keepinventory/core/services/app_version.dart';
import 'package:keepinventory/features/inventory/data/datasources/product_local_datasource.dart';
import 'package:keepinventory/features/inventory/data/repositories/product_repository_impl.dart';
import 'package:keepinventory/features/inventory/domain/bulk_product_edit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  AppVersion.currentForTesting = '0.0.0-test';

  late Directory tempDir;
  late Database db;
  final repository = ProductRepositoryImpl(ProductLocalDatasource());

  // El DatabaseHelper guarda la conexión: se abre una vez y se limpia por test
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('bulk_datasource_test');
    await databaseFactory.setDatabasesPath(tempDir.path);
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    await db.delete('change_log');
    await db.delete('products');
    await db.delete('categories');
  });

  tearDownAll(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<int> insertProduct(String name, double price, {int? categoryId}) =>
      db.insert('products', {
        'name': name,
        'units': 7,
        'price': price,
        'cost': 4.0,
        'category_id': categoryId,
      });

  test(
    'updates several products at once without touching their stock',
    () async {
      final a = await insertProduct('A', 10);
      final b = await insertProduct('B', 20);
      final category = await db.insert('categories', {'name': 'Ropa'});
      final products = await repository.getProducts();

      final changed = await repository.updateMany(
        BulkProductEdit(
          changeCategory: true,
          categoryId: category,
          price: const BulkNumberEdit(BulkNumberMode.percent, 10),
        ),
        products,
      );

      expect(changed, 2);
      final rows = await db.query('products', orderBy: 'id');
      expect(rows.map((r) => r['price']), [11.0, 22.0]);
      expect(rows.map((r) => r['category_id']), [category, category]);
      expect(rows.map((r) => r['units']), [7, 7]);
      expect(rows.map((r) => r['id']), [a, b]);
    },
  );

  test('records one history entry per product in the same group', () async {
    await insertProduct('A', 10);
    await insertProduct('B', 20);
    await db.delete('change_log');
    final products = await repository.getProducts();

    await repository.updateMany(
      const BulkProductEdit(price: BulkNumberEdit(BulkNumberMode.set, 5)),
      products,
    );

    final log = await db.query('change_log', orderBy: 'id');
    expect(log, hasLength(2));
    expect(log.map((r) => r['action']), ['update', 'update']);
    expect(log[0]['group_id'], isNotNull);
    expect(log[0]['group_id'], log[1]['group_id']);
    expect(jsonDecode(log[0]['after_json'] as String), {'price': 5});
  });

  test('is all or nothing when something fails midway', () async {
    final a = await insertProduct('A', 10);
    final b = await insertProduct('B', 20);

    // Un valor que SQLite no admite en la segunda fila deshace también la primera
    await expectLater(
      ProductLocalDatasource().updateMany({
        a: {'price': 99.0},
        b: {'columna_inexistente': 1},
      }),
      throwsA(isA<DatabaseException>()),
    );

    final rows = await db.query('products', orderBy: 'id');
    expect(rows.map((r) => r['price']), [10.0, 20.0]);
    // Ni el cambio de A ni su entrada de historial se conservan
    expect(await db.query('change_log'), isEmpty);
  });

  test('deletes several products logically and groups the history', () async {
    final a = await insertProduct('A', 10);
    final b = await insertProduct('B', 20);
    final keep = await insertProduct('C', 30);
    await db.delete('change_log');

    final deleted = await repository.deleteMany([a, b]);

    expect(deleted, 2);
    final rows = await db.query('products', orderBy: 'id');
    expect(rows.map((r) => r['is_active']), [0, 0, 1]);
    expect(rows.map((r) => r['units']), [0, 0, 7]);
    expect(rows.last['id'], keep);
    final log = await db.query('change_log');
    expect(log, hasLength(2));
    expect(log.map((r) => r['action']), ['delete', 'delete']);
    expect(log[0]['group_id'], log[1]['group_id']);
  });

  test('an edit that changes nothing leaves the history empty', () async {
    await insertProduct('A', 10);
    await db.delete('change_log');
    final products = await repository.getProducts();

    await repository.updateMany(const BulkProductEdit(), products);

    expect(await db.query('change_log'), isEmpty);
  });
}
