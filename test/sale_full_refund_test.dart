import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_helper.dart';
import 'package:keepinventory/core/services/app_version.dart';
import 'package:keepinventory/features/sales/data/datasources/sale_local_datasource.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  AppVersion.currentForTesting = '0.0.0-test';

  late Directory tempDir;
  late Database db;
  final datasource = SaleLocalDatasource();

  // El DatabaseHelper guarda la conexión: se abre una vez y se limpia por test
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('full_refund_test');
    await databaseFactory.setDatabasesPath(tempDir.path);
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    await db.delete('sale_refunds');
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('products');
  });

  tearDownAll(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  /// Vende [quantity] camisetas a 10 € y devuelve la venta ya guardada.
  Future<Sale> soldShirts(int quantity) async {
    final productId = await db.insert('products', {
      'name': 'Camiseta',
      'units': 10,
      'price': 10.0,
      'cost': 4.0,
    });
    await datasource.processSale(
      Sale(
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
      ),
    );
    return (await datasource.getSales()).single;
  }

  test('a fully refunded ticket is kept with total 0 and its refund', () async {
    final sale = await soldShirts(2);

    await datasource.processPartialRefund(
      originalSale: sale,
      itemsToRefund: {sale.items.single: 2},
      packsToRefund: {},
      restockAsComponents: false,
      customRefundAmount: 20,
    );

    final sales = await datasource.getSales();
    expect(sales, hasLength(1));
    final kept = sales.single;
    expect(kept.id, sale.id);
    expect(kept.totalAmount, 0);
    expect(kept.items, isEmpty);
    expect(kept.refunds, hasLength(1));
    expect(kept.refunds.single.amount, 20);
    expect(kept.refunds.single.summary, contains('2× Camiseta'));
    // El stock vuelve al inventario
    final product = await db.query('products');
    expect(product.single['units'], 10);
  });

  test('a partial refund keeps the ticket open with the new total', () async {
    final sale = await soldShirts(3);

    await datasource.processPartialRefund(
      originalSale: sale,
      itemsToRefund: {sale.items.single: 1},
      packsToRefund: {},
      restockAsComponents: false,
      customRefundAmount: 10,
    );

    final kept = (await datasource.getSales()).single;
    expect(kept.totalAmount, 20);
    expect(kept.items.single.quantity, 2);
    expect(kept.refunds, hasLength(1));
  });

  test(
    'refunding what is left of a partly refunded ticket also keeps it',
    () async {
      final sale = await soldShirts(2);
      await datasource.processPartialRefund(
        originalSale: sale,
        itemsToRefund: {sale.items.single: 1},
        packsToRefund: {},
        restockAsComponents: false,
        customRefundAmount: 10,
      );
      final afterFirst = (await datasource.getSales()).single;

      await datasource.processPartialRefund(
        originalSale: afterFirst,
        itemsToRefund: {afterFirst.items.single: 1},
        packsToRefund: {},
        restockAsComponents: false,
        customRefundAmount: 10,
      );

      final kept = (await datasource.getSales()).single;
      expect(kept.totalAmount, 0);
      expect(kept.items, isEmpty);
      // Las dos devoluciones quedan anotadas
      expect(kept.refunds, hasLength(2));
    },
  );
}
