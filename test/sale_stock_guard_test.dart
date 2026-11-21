import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_helper.dart';
import 'package:keepinventory/core/services/app_version.dart';
import 'package:keepinventory/features/sales/data/datasources/sale_local_datasource.dart';
import 'package:keepinventory/features/sales/domain/insufficient_stock_exception.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // La BD se marca con la versión de la app al abrirse
  AppVersion.currentForTesting = '0.0.0-test';

  late Directory tempDir;
  late Database db;
  final datasource = SaleLocalDatasource();

  // El DatabaseHelper guarda la conexión: se abre una vez y se limpia por test
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('stock_guard_test');
    await databaseFactory.setDatabasesPath(tempDir.path);
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('products');
  });

  tearDownAll(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<int> insertProduct(int units) => db.insert('products', {
    'name': 'Camiseta',
    'units': units,
    'price': 10.0,
    'cost': 4.0,
  });

  Sale saleOf(int productId, int quantity) => Sale(
    date: DateTime(2026, 11, 1),
    totalAmount: 10.0 * quantity,
    items: [
      SaleItem(
        productId: productId,
        productName: 'Camiseta',
        quantity: quantity,
        historicalPrice: 10,
        originalPrice: 10,
      ),
    ],
  );

  test(
    'a sale that exceeds the real stock fails and changes nothing',
    () async {
      final id = await insertProduct(1);

      await expectLater(
        datasource.processSale(saleOf(id, 2)),
        throwsA(
          isA<InsufficientStockException>().having(
            (e) => e.name,
            'name',
            'Camiseta',
          ),
        ),
      );

      // Ni la venta ni el descuento de stock se guardan
      expect(await db.query('sales'), isEmpty);
      expect(await db.query('sale_items'), isEmpty);
      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(product.single['units'], 1);
    },
  );

  test('a sale within the stock still goes through and subtracts it', () async {
    final id = await insertProduct(3);

    final saleId = await datasource.processSale(saleOf(id, 3));

    expect(saleId, greaterThan(0));
    final product = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(product.single['units'], 0);
  });

  test('stock is checked per line when a product appears twice', () async {
    final id = await insertProduct(3);
    final sale = Sale(
      date: DateTime(2026, 11, 1),
      totalAmount: 40,
      items: [
        SaleItem(
          productId: id,
          productName: 'Camiseta',
          quantity: 2,
          historicalPrice: 10,
          originalPrice: 10,
        ),
        SaleItem(
          productId: id,
          productName: 'Camiseta',
          quantity: 2,
          historicalPrice: 10,
          originalPrice: 10,
        ),
      ],
    );

    // 2 + 2 > 3: la segunda línea ya no alcanza
    await expectLater(
      datasource.processSale(sale),
      throwsA(isA<InsufficientStockException>()),
    );
    final product = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(product.single['units'], 3);
  });
}
