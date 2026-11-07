import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/inventory_view.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';

Product _p(
  String name, {
  int units = 10,
  double price = 10,
  double cost = 4,
  int? promo,
}) => Product(
  name: name,
  units: units,
  price: price,
  cost: cost,
  promotionId: promo,
);

void main() {
  group('StockLevel', () {
    test('classifies by threshold', () {
      expect(StockLevel.of(0), StockLevel.out);
      expect(StockLevel.of(-2), StockLevel.out);
      expect(StockLevel.of(1), StockLevel.low);
      expect(StockLevel.of(StockLevel.lowThreshold), StockLevel.low);
      expect(StockLevel.of(StockLevel.lowThreshold + 1), StockLevel.ok);
    });
  });

  group('ProductMargin', () {
    test('amount and percent over sale price', () {
      final p = _p('a', price: 8, cost: 2);
      expect(p.marginAmount, 6);
      expect(p.marginPercent, closeTo(75, 1e-9));
    });

    test(
      'percent is null for free products and negative when selling at loss',
      () {
        expect(_p('a', price: 0, cost: 1).marginPercent, isNull);
        expect(_p('a', price: 5, cost: 10).marginPercent, closeTo(-100, 1e-9));
      },
    );
  });

  group('InventorySummary', () {
    test('counts products, units, low and out of stock', () {
      final s = InventorySummary.of([
        _p('a', units: 10),
        _p('b', units: 2),
        _p('c', units: 0),
        _p('d', units: -1),
      ]);
      expect(s.products, 4);
      expect(s.units, 12); // negativas no restan
      expect(s.lowStock, 1);
      expect(s.outOfStock, 2);
    });
  });

  group('InventoryView.apply', () {
    final products = [
      _p('Taza', units: 10, price: 8, cost: 2, promo: 1),
      _p('collar', units: 2, price: 15, cost: 5),
      _p('Anillo', units: 0, price: 20, cost: 18, promo: 99),
    ];

    test('search is case-insensitive', () {
      expect(InventoryView.apply(products, query: 'COLL').map((p) => p.name), [
        'collar',
      ]);
    });

    test('filters by stock level', () {
      expect(
        InventoryView.apply(
          products,
          filter: InventoryFilter.lowStock,
        ).map((p) => p.name),
        ['collar'],
      );
      expect(
        InventoryView.apply(
          products,
          filter: InventoryFilter.outOfStock,
        ).map((p) => p.name),
        ['Anillo'],
      );
    });

    test('promotion filter ignores deleted promotions', () {
      expect(
        InventoryView.apply(
          products,
          filter: InventoryFilter.withPromotion,
          validPromotionIds: {1},
        ).map((p) => p.name),
        ['Taza'],
      );
    });

    test('sorts by name ignoring case, both directions', () {
      expect(
        InventoryView.apply(
          products,
          sort: InventorySort.name,
        ).map((p) => p.name),
        ['Anillo', 'collar', 'Taza'],
      );
      expect(
        InventoryView.apply(
          products,
          sort: InventorySort.name,
          ascending: false,
        ).map((p) => p.name),
        ['Taza', 'collar', 'Anillo'],
      );
    });

    test('sorts by margin amount', () {
      expect(
        InventoryView.apply(
          products,
          sort: InventorySort.margin,
        ).map((p) => p.name),
        ['Anillo', 'Taza', 'collar'], // 2, 6, 10
      );
    });

    test('keeps original order when no sort is given', () {
      expect(InventoryView.apply(products).map((p) => p.name), [
        'Taza',
        'collar',
        'Anillo',
      ]);
    });
  });
}
