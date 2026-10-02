import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:keepinventory/features/sales/domain/sale_refund_calculator.dart';

void main() {
  group('SaleRefundCalculator', () {
    test('keeps paid prices for untouched items and packs', () {
      final item = SaleItem(
        productId: 1,
        quantity: 2,
        historicalPrice: 2.5,
        originalPrice: 3,
      );
      final pack = SalePackItem(
        saleId: 1,
        packId: 1,
        packName: 'Pack',
        quantity: 1,
        historicalPrice: 4,
      );

      final total = SaleRefundCalculator.calculateRemainingCartValue(
        originalItemQuantities: {item: 2},
        keptItemQuantities: {item: 2},
        keptPackQuantities: {pack: 1},
      );

      // 2 * 2.5 (precio cobrado) + 4
      expect(total, 9);
    });

    test('keeps paid price of a non-promoted item after a partial return', () {
      final item = SaleItem(
        productId: 1,
        quantity: 3,
        historicalPrice: 2.5,
        originalPrice: 3,
      );

      final total = SaleRefundCalculator.calculateRemainingCartValue(
        originalItemQuantities: {item: 3},
        keptItemQuantities: {item: 2},
        keptPackQuantities: {},
      );

      expect(total, 5);
    });

    test(
      'uses historical price when a legacy item has zero original price',
      () {
        final legacyItem = SaleItem(
          productId: 1,
          quantity: 2,
          historicalPrice: 5,
        );

        final total = SaleRefundCalculator.calculateRemainingCartValue(
          originalItemQuantities: {legacyItem: 2},
          keptItemQuantities: {legacyItem: 1},
          keptPackQuantities: {},
        );

        expect(total, 5);
      },
    );

    test(
      'applies percentage promotions when the combined threshold is met',
      () {
        final items = [
          _promotedItem(1, originalPrice: 10, quantity: 3),
          _promotedItem(2, originalPrice: 5, quantity: 1),
        ];

        final total = SaleRefundCalculator.calculateRemainingCartValue(
          originalItemQuantities: {items[0]: 3, items[1]: 1},
          keptItemQuantities: {items[0]: 2, items[1]: 1},
          keptPackQuantities: {},
        );

        // (2 * 10 + 1 * 5) * 0.8
        expect(total, 20);
      },
    );

    test('uses original prices when the promotion threshold is not met', () {
      final items = [
        _promotedItem(1, originalPrice: 10, threshold: 4, quantity: 3),
        _promotedItem(2, originalPrice: 5, threshold: 4, quantity: 1),
      ];

      final total = SaleRefundCalculator.calculateRemainingCartValue(
        originalItemQuantities: {items[0]: 3, items[1]: 1},
        keptItemQuantities: {items[0]: 2, items[1]: 1},
        keptPackQuantities: {},
      );

      expect(total, 25);
    });

    test('applies fixed bundle price to the highest-priced items first', () {
      final expensive = _promotedItem(
        1,
        originalPrice: 10,
        type: 'bundle_fixed_price',
        threshold: 2,
        discount: 12,
        quantity: 3,
      );
      final cheap = _promotedItem(
        2,
        originalPrice: 5,
        type: 'bundle_fixed_price',
        threshold: 2,
        discount: 12,
        quantity: 1,
      );

      final total = SaleRefundCalculator.calculateRemainingCartValue(
        originalItemQuantities: {expensive: 3, cheap: 1},
        keptItemQuantities: {expensive: 2, cheap: 1},
        keptPackQuantities: {},
      );

      expect(total, 17);
    });

    test('does not recalculate a promotion group that was not touched', () {
      // Grupo con promo 1: no se devuelve nada, se cobró a 8 (original 10).
      final untouchedA = _promotedItem(
        1,
        originalPrice: 10,
        quantity: 2,
        historicalPrice: 8,
      );
      final untouchedB = _promotedItem(
        2,
        originalPrice: 10,
        quantity: 1,
        historicalPrice: 8,
      );
      // Ítem suelto del que sí se devuelve una unidad.
      final loose = SaleItem(
        productId: 3,
        quantity: 2,
        historicalPrice: 4,
        originalPrice: 4,
      );

      final total = SaleRefundCalculator.calculateRemainingCartValue(
        originalItemQuantities: {untouchedA: 2, untouchedB: 1, loose: 2},
        keptItemQuantities: {untouchedA: 2, untouchedB: 1, loose: 1},
        keptPackQuantities: {},
      );

      // 3 * 8 (precio cobrado, sin recalcular) + 1 * 4
      expect(total, 28);
    });

    test('recalculates only the promotion group affected by the return', () {
      // Grupo de promo 1, se devuelve una unidad -> deja de cumplir umbral 3.
      final affectedA = _promotedItem(
        1,
        originalPrice: 10,
        quantity: 2,
        historicalPrice: 8,
      );
      final affectedB = _promotedItem(
        2,
        originalPrice: 10,
        quantity: 1,
        historicalPrice: 8,
      );
      // Otro grupo (promo 2) sin tocar, cobrado a 4 (original 5).
      final otherGroup = SaleItem(
        productId: 4,
        quantity: 3,
        historicalPrice: 4,
        originalPrice: 5,
        promotionId: 2,
        promoType: 'percentage',
        promoThreshold: 3,
        promoDiscount: 20,
      );

      final total = SaleRefundCalculator.calculateRemainingCartValue(
        originalItemQuantities: {affectedA: 2, affectedB: 1, otherGroup: 3},
        keptItemQuantities: {affectedA: 1, affectedB: 1, otherGroup: 3},
        keptPackQuantities: {},
      );

      // Grupo afectado: 2 * 10 (precio completo) + otro grupo: 3 * 4
      expect(total, 32);
    });
  });
}

SaleItem _promotedItem(
  int productId, {
  required double originalPrice,
  double? historicalPrice,
  String type = 'percentage',
  int threshold = 3,
  double discount = 20,
  int quantity = 1,
}) {
  return SaleItem(
    productId: productId,
    quantity: quantity,
    historicalPrice: historicalPrice ?? originalPrice,
    originalPrice: originalPrice,
    promotionId: 1,
    promoType: type,
    promoThreshold: threshold,
    promoDiscount: discount,
  );
}
