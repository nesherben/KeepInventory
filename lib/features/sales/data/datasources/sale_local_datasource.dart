import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/sale.dart';

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
              productName:
                  itemMap['product_name'] as String? ?? 'Desconocido/Eliminado',
              quantity: itemMap['quantity'] as int,
              historicalPrice: (itemMap['historical_price'] as num).toDouble(),
              originalPrice:
                  (itemMap['original_price'] as num?)?.toDouble() ??
                  (itemMap['historical_price'] as num).toDouble(),
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
              packName:
                  pMap['pack_name'] as String? ?? 'Pack Eliminado/Desconocido',
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
    required bool restockPacks,
    required double customRefundAmount,
  }) async {
    final database = await db;
    await database.transaction((txn) async {
      for (var entry in itemsToRefund.entries) {
        if (entry.value > 0)
          await txn.rawUpdate(
            'UPDATE products SET units = units + ? WHERE id = ?',
            [entry.value, entry.key.productId],
          );
      }
      for (var entry in packsToRefund.entries) {
        if (entry.value > 0 && restockPacks)
          await txn.rawUpdate(
            'UPDATE packs SET units = units + ? WHERE id = ?',
            [entry.value, entry.key.packId],
          );
      }
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

      final remainingItems = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [originalSale.id],
      );
      final remainingPacks = await txn.query(
        'sale_packs',
        where: 'sale_id = ?',
        whereArgs: [originalSale.id],
      );

      if (remainingItems.isEmpty && remainingPacks.isEmpty) {
        await txn.delete(
          'sales',
          where: 'id = ?',
          whereArgs: [originalSale.id],
        );
      } else {
        final double newTotalAmount =
            originalSale.totalAmount - customRefundAmount;
        await txn.update(
          'sales',
          {'total_amount': newTotalAmount > 0 ? newTotalAmount : 0.0},
          where: 'id = ?',
          whereArgs: [originalSale.id],
        );

        double currentRemainingValue = 0.0;
        for (var row in remainingItems)
          currentRemainingValue +=
              (row['historical_price'] as num) * (row['quantity'] as int);
        for (var row in remainingPacks)
          currentRemainingValue +=
              (row['historical_price'] as num) * (row['quantity'] as int);

        if (currentRemainingValue > 0 && newTotalAmount > 0) {
          final double ratio = newTotalAmount / currentRemainingValue;
          for (var row in remainingItems)
            await txn.update(
              'sale_items',
              {'historical_price': (row['historical_price'] as num) * ratio},
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          for (var row in remainingPacks)
            await txn.update(
              'sale_packs',
              {'historical_price': (row['historical_price'] as num) * ratio},
              where: 'id = ?',
              whereArgs: [row['id']],
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
