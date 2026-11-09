import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../promotions/domain/combo.dart';
import '../../domain/sale.dart';
import '../../domain/sale_refund_calculator.dart';

class SaleLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  /// Guarda la venta (y descuenta stock); devuelve su id.
  Future<int> processSale(Sale sale) async {
    final database = await db;
    return database.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'date': sale.date.toIso8601String(),
        'total_amount': sale.totalAmount,
        'fair_name': sale.fairName,
        'payment_method': sale.paymentMethod.dbValue,
      });

      // Combos con su definición congelada; los ids de la venta en memoria
      // son provisionales y se traducen a los reales
      final comboIds = <int, int>{};
      for (final combo in sale.combos) {
        final id = await txn.insert('sale_combos', {
          'sale_id': saleId,
          'combo_id': combo.comboId,
          'name': combo.name,
          'price': combo.price,
          'quantity': combo.quantity,
          'definition': combo.asCombo.encodeDefinition(),
        });
        if (combo.id != null) comboIds[combo.id!] = id;
      }

      for (var item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'historical_price': item.historicalPrice,
          'original_price': item.originalPrice,
          'promotion_id': item.promotionId,
          'promo_type': item.promoType,
          'promo_threshold': item.promoThreshold,
          'promo_discount': item.promoDiscount,
          'sale_combo_id': item.saleComboId == null
              ? null
              : comboIds[item.saleComboId],
        });

        await txn.rawUpdate(
          'UPDATE products SET units = units - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      for (var packItem in sale.packItems) {
        await txn.insert('sale_packs', {
          'sale_id': saleId,
          'pack_id': packItem.packId,
          'quantity': packItem.quantity,
          'historical_price': packItem.historicalPrice,
        });

        await txn.rawUpdate('UPDATE packs SET units = units - ? WHERE id = ?', [
          packItem.quantity,
          packItem.packId,
        ]);
      }
      return saleId;
    });
  }

  Future<List<Sale>> getSales() async {
    final database = await db;
    final salesMaps = await database.query('sales', orderBy: 'date DESC');
    List<Sale> salesList = [];

    for (var saleMap in salesMaps) {
      final saleId = saleMap['id'] as int;

      final itemsMaps = await database.rawQuery(
        '''
        SELECT si.*, p.name as product_name 
        FROM sale_items si 
        LEFT JOIN products p ON si.product_id = p.id 
        WHERE si.sale_id = ?
      ''',
        [saleId],
      );

      List<SaleItem> itemsList = itemsMaps
          .map(
            (itemMap) => SaleItem(
              id: itemMap['id'] as int,
              saleId: itemMap['sale_id'] as int,
              productId: itemMap['product_id'] as int,
              productName: itemMap['product_name'] as String?,
              quantity: itemMap['quantity'] as int,
              historicalPrice: (itemMap['historical_price'] as num).toDouble(),
              originalPrice: _originalPrice(itemMap),
              promotionId: itemMap['promotion_id'] as int?,
              promoType: itemMap['promo_type'] as String?,
              promoThreshold: itemMap['promo_threshold'] as int?,
              promoDiscount: (itemMap['promo_discount'] as num?)?.toDouble(),
              saleComboId: itemMap['sale_combo_id'] as int?,
            ),
          )
          .toList();

      final packItemsMaps = await database.rawQuery(
        '''
        SELECT sp.*, p.name as pack_name 
        FROM sale_packs sp 
        LEFT JOIN packs p ON sp.pack_id = p.id 
        WHERE sp.sale_id = ?
      ''',
        [saleId],
      );

      List<SalePackItem> packItemsList = packItemsMaps
          .map(
            (pMap) => SalePackItem(
              id: pMap['id'] as int?,
              saleId: pMap['sale_id'] as int,
              packId: pMap['pack_id'] as int,
              packName: pMap['pack_name'] as String?,
              quantity: pMap['quantity'] as int,
              historicalPrice: (pMap['historical_price'] as num).toDouble(),
            ),
          )
          .toList();

      final comboMaps = await database.query(
        'sale_combos',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final combosList = [
        for (final c in comboMaps)
          SaleCombo(
            id: c['id'] as int,
            comboId: c['combo_id'] as int?,
            name: c['name'] as String,
            price: (c['price'] as num).toDouble(),
            quantity: c['quantity'] as int,
            slots: Combo.decodeDefinition(c['definition'] as String?),
          ),
      ];

      salesList.add(
        Sale(
          id: saleId,
          date: DateTime.parse(saleMap['date'] as String),
          totalAmount: (saleMap['total_amount'] as num).toDouble(),
          fairName: saleMap['fair_name'] as String?,
          items: itemsList,
          packItems: packItemsList,
          paymentMethod: PaymentMethod.fromDb(saleMap['payment_method']),
          combos: combosList,
        ),
      );
    }
    return salesList;
  }

  double _originalPrice(Map<String, Object?> itemMap) {
    final historicalPrice = (itemMap['historical_price'] as num).toDouble();
    final originalPrice = (itemMap['original_price'] as num?)?.toDouble();
    if (originalPrice == null || (originalPrice == 0 && historicalPrice > 0)) {
      return historicalPrice;
    }
    return originalPrice;
  }

  Future<void> refundSale(Sale sale) async {
    final database = await db;
    await database.transaction((txn) async {
      for (var item in sale.items) {
        await txn.rawUpdate(
          'UPDATE products SET units = units + ?, is_active = 1 WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      for (var packItem in sale.packItems) {
        await txn.rawUpdate('UPDATE packs SET units = units + ? WHERE id = ?', [
          packItem.quantity,
          packItem.packId,
        ]);
      }
      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );
      await txn.delete(
        'sale_packs',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );
      await txn.delete(
        'sale_combos',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );
      await txn.delete('sales', where: 'id = ?', whereArgs: [sale.id]);
    });
  }

  Future<void> processPartialRefund({
    required Sale originalSale,
    required Map<SaleItem, int> itemsToRefund,
    required Map<SalePackItem, int> packsToRefund,
    required bool restockAsComponents,
    required double customRefundAmount,
  }) async {
    final database = await db;
    await database.transaction((txn) async {
      // 1. DEVOLUCIÓN DE PRODUCTOS SUELTOS
      for (var entry in itemsToRefund.entries) {
        if (entry.value > 0) {
          await txn.rawUpdate(
            'UPDATE products SET units = units + ? WHERE id = ?',
            [entry.value, entry.key.productId],
          );
        }
      }

      // 2. DEVOLUCIÓN DE PACKS
      for (var entry in packsToRefund.entries) {
        final refundQty = entry.value;
        final packId = entry.key.packId;

        if (refundQty > 0) {
          if (restockAsComponents) {
            final components = await txn.query(
              'pack_items',
              columns: ['product_id', 'quantity'],
              where: 'pack_id = ?',
              whereArgs: [packId],
            );

            for (var component in components) {
              final productId = component['product_id'] as int;
              final qtyPerPack = component['quantity'] as int;
              final totalToRestock = qtyPerPack * refundQty;

              await txn.rawUpdate(
                'UPDATE products SET units = units + ? WHERE id = ?',
                [totalToRestock, productId],
              );
            }
          } else {
            await txn.rawUpdate(
              'UPDATE packs SET units = units + ? WHERE id = ?',
              [refundQty, packId],
            );
          }
        }
      }

      // 3. LÍNEAS QUE QUEDAN: se recalculan en lógica pura (promociones y
      // combos afectados) y se reescriben para que la suma cuadre
      final remaining = SaleRefundCalculator.remainingAfterRefund(
        sale: originalSale,
        itemsToRefund: itemsToRefund,
      );
      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [originalSale.id],
      );
      await txn.delete(
        'sale_combos',
        where: 'sale_id = ?',
        whereArgs: [originalSale.id],
      );
      for (final combo in remaining.combos) {
        await txn.insert('sale_combos', {
          'id': combo.id,
          'sale_id': originalSale.id,
          'combo_id': combo.comboId,
          'name': combo.name,
          'price': combo.price,
          'quantity': combo.quantity,
          'definition': combo.asCombo.encodeDefinition(),
        });
      }
      for (final item in remaining.items) {
        await txn.insert('sale_items', {
          'sale_id': originalSale.id,
          'product_id': item.productId,
          'quantity': item.quantity,
          'historical_price': item.historicalPrice,
          'original_price': item.originalPrice,
          'promotion_id': item.promotionId,
          'promo_type': item.promoType,
          'promo_threshold': item.promoThreshold,
          'promo_discount': item.promoDiscount,
          'sale_combo_id': item.saleComboId,
        });
      }

      // 4. LIMPIEZA DE LA VENTA: SALE_PACKS
      for (var entry in packsToRefund.entries) {
        if (entry.value >= entry.key.quantity) {
          await txn.delete(
            'sale_packs',
            where: 'id = ?',
            whereArgs: [entry.key.id],
          );
        } else if (entry.value > 0) {
          await txn.rawUpdate(
            'UPDATE sale_packs SET quantity = quantity - ? WHERE id = ?',
            [entry.value, entry.key.id],
          );
        }
      }

      // 5. CONTABILIDAD: venta vacía => se borra; si no, nuevo total
      final remainingItemRows = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [originalSale.id],
      );
      final remainingPackRows = await txn.query(
        'sale_packs',
        where: 'sale_id = ?',
        whereArgs: [originalSale.id],
      );

      if (remainingItemRows.isEmpty && remainingPackRows.isEmpty) {
        await txn.delete(
          'sale_combos',
          where: 'sale_id = ?',
          whereArgs: [originalSale.id],
        );
        await txn.delete(
          'sales',
          where: 'id = ?',
          whereArgs: [originalSale.id],
        );
        return;
      }

      final newTotalAmount = originalSale.totalAmount - customRefundAmount;
      await txn.update(
        'sales',
        {'total_amount': newTotalAmount > 0 ? newTotalAmount : 0.0},
        where: 'id = ?',
        whereArgs: [originalSale.id],
      );
    });
  }

  /// Asigna (o quita, con null) la feria a todos los tickets de un día.
  Future<void> updateFairNameForDate(
    String datePrefix,
    String? fairName,
  ) async {
    final database = await db;
    await database.transaction((txn) async {
      if (fairName != null) await _ensureFair(txn, fairName);
      await txn.rawUpdate('UPDATE sales SET fair_name = ? WHERE date LIKE ?', [
        fairName,
        '$datePrefix%',
      ]);
    });
  }

  /// Cambia (o quita, con null) la feria de TODOS los tickets que la tienen,
  /// sean del día que sean. La feria sigue en el catálogo.
  Future<void> reassignFair(String fairName, String? newFairName) async {
    final database = await db;
    await database.transaction((txn) async {
      if (newFairName != null) await _ensureFair(txn, newFairName);
      await txn.rawUpdate(
        'UPDATE sales SET fair_name = ? WHERE fair_name = ?',
        [newFairName, fairName],
      );
    });
  }

  /// Catálogo de ferias (también las que aún no tienen tickets).
  Future<List<String>> getAvailableFairs() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT name FROM fairs ORDER BY name COLLATE NOCASE',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<int> countSalesForFair(String fairName) async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS n FROM sales WHERE fair_name = ?',
      [fairName],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Quita la feria del catálogo; sus tickets se quedan sin feria (no se
  /// borran).
  Future<void> deleteFair(String fairName) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE sales SET fair_name = NULL WHERE fair_name = ?',
        [fairName],
      );
      await txn.delete('fairs', where: 'name = ?', whereArgs: [fairName]);
    });
  }

  Future<void> _ensureFair(Transaction txn, String name) => txn.insert(
    'fairs',
    {'name': name.trim()},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}
