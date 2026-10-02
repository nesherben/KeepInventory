import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/sale.dart';
import '../../domain/sale_refund_calculator.dart';

class SaleLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Database> get db async => await _databaseHelper.database;

  Future<void> processSale(Sale sale) async {
    final database = await db;
    await database.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'date': sale.date.toIso8601String(),
        'total_amount': sale.totalAmount,
        'fair_name': sale.fairName,
      });

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

      salesList.add(
        Sale(
          id: saleId,
          date: DateTime.parse(saleMap['date'] as String),
          totalAmount: (saleMap['total_amount'] as num).toDouble(),
          fairName: saleMap['fair_name'] as String?,
          items: itemsList,
          packItems: packItemsList,
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

      // 3. LIMPIEZA DE LA VENTA: SALE_ITEMS
      for (var entry in itemsToRefund.entries) {
        if (entry.value >= entry.key.quantity) {
          await txn.delete(
            'sale_items',
            where: 'id = ?',
            whereArgs: [entry.key.id],
          );
        } else if (entry.value > 0) {
          await txn.rawUpdate(
            'UPDATE sale_items SET quantity = quantity - ? WHERE id = ?',
            [entry.value, entry.key.id],
          );
        }
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

      // 5. CONTABILIDAD: solo se repreciaran los grupos de promoción afectados
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

      // Promociones tocadas por la devolución
      final affectedPromotionIds = <int>{
        for (final entry in itemsToRefund.entries)
          if (entry.value > 0 && entry.key.promotionId != null)
            entry.key.promotionId!,
      };

      for (final promotionId in affectedPromotionIds) {
        final groupItems = originalSale.items
            .where((i) => i.promotionId == promotionId)
            .toList();
        final keptQuantities = <SaleItem, int>{
          for (final item in groupItems)
            item: item.quantity - (itemsToRefund[item] ?? 0),
        };
        final keptItems = groupItems
            .where((i) => keptQuantities[i]! > 0)
            .toList();
        if (keptItems.isEmpty) continue;

        final newTotalGroup = SaleRefundCalculator.calculateGroupValue(
          keptItems: keptItems,
          keptQuantities: keptQuantities,
        );
        final keptUnits = keptItems.fold<int>(
          0,
          (t, i) => t + keptQuantities[i]!,
        );
        if (keptUnits == 0) continue;

        // Reparto proporcional al precio completo de cada línea
        final fullValue = keptItems.fold<double>(
          0,
          (t, i) => t + i.refundUnitPrice * keptQuantities[i]!,
        );
        for (final item in keptItems) {
          final share = fullValue > 0
              ? (item.refundUnitPrice * keptQuantities[item]!) / fullValue
              : keptQuantities[item]! / keptUnits;
          final lineTotal = newTotalGroup * share;
          await txn.update(
            'sale_items',
            {'historical_price': lineTotal / keptQuantities[item]!},
            where: 'id = ?',
            whereArgs: [item.id],
          );
        }
      }
    });
  }

  Future<void> updateFairNameForDate(
    String datePrefix,
    String? fairName,
  ) async {
    final database = await db;
    await database.rawUpdate(
      'UPDATE sales SET fair_name = ? WHERE date LIKE ?',
      [fairName, '$datePrefix%'],
    );
  }

  Future<List<String>> getAvailableFairs() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.rawQuery(
      'SELECT DISTINCT fair_name FROM sales WHERE fair_name IS NOT NULL AND fair_name != ""',
    );
    return maps.map((m) => m['fair_name'] as String).toList();
  }
}
