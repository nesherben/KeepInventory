import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:keepinventory/features/sales/presentation/sale_history_group.dart';

void main() {
  group('filterAndGroupSales', () {
    final recentFairSale = _sale(
      id: 3,
      date: DateTime(2026, 10, 3),
      fairName: 'Autumn Fair',
      productName: 'Red mug',
      total: 10,
    );
    final olderFairSale = _sale(
      id: 2,
      date: DateTime(2026, 10, 2),
      fairName: 'Autumn Fair',
      productName: 'Blue mug',
      total: 5,
    );
    final standaloneSale = _sale(
      id: 1,
      date: DateTime(2026, 10, 1),
      productName: 'Brush',
      total: 3,
    );

    test('preserves insertion order and date prefixes when grouping', () {
      final groups = filterAndGroupSales([
        recentFairSale,
        olderFairSale,
        standaloneSale,
      ], '');

      expect(groups.map((group) => group.key).toList(), [
        '🎪 Autumn Fair',
        '📅 01/10/2026',
      ]);
      expect(groups.first.sales, [recentFairSale, olderFairSale]);
      expect(groups.first.datePrefix, '2026-10-02');
      expect(groups.first.total, 15);
      expect(groups.first.fairName, 'Autumn Fair');
      expect(groups.last.isFair, isFalse);
    });

    test('filters by product name without changing group identity', () {
      final groups = filterAndGroupSales([
        recentFairSale,
        olderFairSale,
        standaloneSale,
      ], 'RED MUG');

      expect(groups, hasLength(1));
      expect(groups.single.key, '🎪 Autumn Fair');
      expect(groups.single.sales, [recentFairSale]);
    });
  });
}

Sale _sale({
  required int id,
  required DateTime date,
  String? fairName,
  required String productName,
  required double total,
}) {
  return Sale(
    id: id,
    date: date,
    totalAmount: total,
    fairName: fairName,
    items: [
      SaleItem(
        productId: id,
        productName: productName,
        quantity: 1,
        historicalPrice: total,
      ),
    ],
  );
}
