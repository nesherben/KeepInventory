import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/manual_line_discount.dart';

void main() {
  group('ManualLineDiscount', () {
    test('percentage applies to the whole line total', () {
      const discount = ManualLineDiscount.percent(10);

      expect(discount.discountOn(12), 1.2);
      expect(discount.apply(12), 10.8);
    });

    test('fixed amount is subtracted from the line total', () {
      const discount = ManualLineDiscount.amount(2);

      expect(discount.discountOn(30), 2);
      expect(discount.apply(30), 28);
    });

    test('final price converts into an amount discount', () {
      final discount = ManualLineDiscount.fromFinalPrice(
        finalTotal: 8,
        lineTotal: 12,
      );

      expect(discount.type, ManualDiscountType.amount);
      expect(discount.value, 4);
      expect(discount.apply(12), 8);
    });

    test('line price never drops below zero', () {
      expect(const ManualLineDiscount.amount(50).apply(12), 0);
      expect(const ManualLineDiscount.percent(150).apply(12), 0);
      expect(const ManualLineDiscount.amount(50).discountOn(12), 12);
    });

    test('rounds to cents', () {
      // 33,33 % de 10 = 3,333… → 3,33
      const discount = ManualLineDiscount.percent(33.33);

      expect(discount.discountOn(10), 3.33);
      expect(discount.apply(10), 6.67);
    });

    test('ignores empty, negative and invalid values', () {
      expect(const ManualLineDiscount.amount(-3).discountOn(12), 0);
      expect(const ManualLineDiscount.percent(double.nan).discountOn(12), 0);
      expect(const ManualLineDiscount.percent(10).discountOn(0), 0);
    });

    test('database values round-trip and unknown ones are null', () {
      expect(ManualDiscountType.fromDb('percent'), ManualDiscountType.percent);
      expect(ManualDiscountType.fromDb('amount'), ManualDiscountType.amount);
      expect(ManualDiscountType.fromDb(null), isNull);
      expect(ManualDiscountType.fromDb('otro'), isNull);
    });

    test('percentOf converts any discount to a percentage of the line', () {
      expect(const ManualLineDiscount.percent(10).percentOf(12), 10);
      expect(const ManualLineDiscount.amount(3).percentOf(12), 25);
      expect(const ManualLineDiscount.amount(99).percentOf(12), 100);
      expect(const ManualLineDiscount.percent(10).percentOf(0), 0);
    });

    test('switching mode round-trips without losing the discount', () {
      const subtotal = 24.0;
      // 10 % → importe → precio final → de nuevo importe: siempre 2,40 €
      final percent = const ManualLineDiscount.percent(10);
      final amount = ManualLineDiscount.amount(percent.discountOn(subtotal));
      final fromFinal = ManualLineDiscount.fromFinalPrice(
        finalTotal: amount.apply(subtotal),
        lineTotal: subtotal,
      );

      expect(amount.value, 2.4);
      expect(fromFinal.value, 2.4);
      expect(fromFinal.percentOf(subtotal), 10);
    });

    test('a final price of zero makes the line free', () {
      final discount = ManualLineDiscount.fromFinalPrice(
        finalTotal: 0,
        lineTotal: 12,
      );

      expect(discount.value, 12);
      expect(discount.apply(12), 0);
      expect(discount.percentOf(12), 100);
    });

    test('has value equality', () {
      expect(
        const ManualLineDiscount.percent(10),
        const ManualLineDiscount.percent(10),
      );
      expect(
        const ManualLineDiscount.percent(10) ==
            const ManualLineDiscount.amount(10),
        isFalse,
      );
    });
  });
}
