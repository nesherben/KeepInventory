import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/bulk_product_edit.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';

Product _product({double price = 10, double cost = 4, int? category}) =>
    Product(
      id: 1,
      name: 'Camiseta',
      units: 5,
      price: price,
      cost: cost,
      categoryId: category,
    );

void main() {
  group('BulkNumberEdit', () {
    test('keep leaves the value untouched', () {
      expect(const BulkNumberEdit.keep().apply(12.5), 12.5);
    });

    test('set gives everyone the same value', () {
      expect(const BulkNumberEdit(BulkNumberMode.set, 9.99).apply(12.5), 9.99);
    });

    test('percent raises and lowers, rounded to cents', () {
      expect(
        const BulkNumberEdit(BulkNumberMode.percent, 10).apply(10),
        closeTo(11, 1e-9),
      );
      expect(
        const BulkNumberEdit(BulkNumberMode.percent, -10).apply(12.5),
        11.25,
      );
      // 33 % de 10,05 = 13,3665 → 13,37
      expect(
        const BulkNumberEdit(BulkNumberMode.percent, 33).apply(10.05),
        13.37,
      );
    });

    test('amount adds and subtracts', () {
      expect(const BulkNumberEdit(BulkNumberMode.amount, 2).apply(10), 12);
      expect(const BulkNumberEdit(BulkNumberMode.amount, -2.5).apply(10), 7.5);
    });

    test('never goes below zero', () {
      expect(const BulkNumberEdit(BulkNumberMode.amount, -50).apply(10), 0);
      expect(const BulkNumberEdit(BulkNumberMode.percent, -150).apply(10), 0);
      expect(const BulkNumberEdit(BulkNumberMode.set, -3).apply(10), 0);
    });

    test('an invalid number keeps the current value', () {
      expect(
        const BulkNumberEdit(BulkNumberMode.set, double.nan).apply(10),
        10,
      );
      expect(
        const BulkNumberEdit(BulkNumberMode.percent, double.infinity).apply(10),
        10,
      );
    });
  });

  group('BulkProductEdit', () {
    test('an edit that marks nothing is empty', () {
      expect(const BulkProductEdit().isEmpty, isTrue);
      expect(const BulkProductEdit().valuesFor(_product()), isEmpty);
    });

    test('only the marked changes are applied', () {
      const edit = BulkProductEdit(
        changeCategory: true,
        categoryId: 3,
        price: BulkNumberEdit(BulkNumberMode.percent, 10),
      );

      final values = edit.valuesFor(_product(price: 20, cost: 4));

      expect(edit.isEmpty, isFalse);
      expect(values, {'category_id': 3, 'price': 22.0});
      // El coste no se menciona: no se toca
      expect(values.containsKey('cost'), isFalse);
    });

    test('null category and promotion mean "remove"', () {
      const edit = BulkProductEdit(changeCategory: true, changePromotion: true);

      expect(edit.valuesFor(_product(category: 2)), {
        'category_id': null,
        'promotion_id': null,
      });
    });

    test('each product gets its own computed price', () {
      const edit = BulkProductEdit(
        price: BulkNumberEdit(BulkNumberMode.amount, -1),
      );

      expect(edit.valuesFor(_product(price: 10))['price'], 9);
      expect(edit.valuesFor(_product(price: 0.5))['price'], 0);
    });
  });
}
