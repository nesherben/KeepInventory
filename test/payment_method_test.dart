import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:keepinventory/features/sales/domain/sale_from_cart_factory.dart';

Sale _sale(double total, PaymentMethod method) => Sale(
  date: DateTime(2026, 11, 7),
  totalAmount: total,
  items: const [],
  paymentMethod: method,
);

void main() {
  group('PaymentMethod.fromDb', () {
    test('maps stored values', () {
      expect(PaymentMethod.fromDb('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromDb('paypal'), PaymentMethod.paypal);
      expect(PaymentMethod.fromDb('bizum'), PaymentMethod.bizum);
    });

    test('treats null or unknown values (old sales) as unspecified', () {
      expect(PaymentMethod.fromDb(null), PaymentMethod.unspecified);
      expect(PaymentMethod.fromDb('tarjeta'), PaymentMethod.unspecified);
    });

    test('round-trips every method, unspecified stored as NULL', () {
      for (final m in PaymentMethod.values) {
        expect(PaymentMethod.fromDb(m.dbValue), m);
      }
      expect(PaymentMethod.unspecified.dbValue, isNull);
    });

    test('unspecified cannot be selected at checkout', () {
      expect(
        PaymentMethod.selectable,
        isNot(contains(PaymentMethod.unspecified)),
      );
      expect(PaymentMethod.selectable, contains(PaymentMethod.defaultMethod));
    });
  });

  group('PaymentMethod.totalsOf', () {
    test('sums per method and includes methods without sales as 0', () {
      final totals = PaymentMethod.totalsOf([
        _sale(10, PaymentMethod.cash),
        _sale(5.5, PaymentMethod.cash),
        _sale(7, PaymentMethod.bizum),
        _sale(4, PaymentMethod.unspecified),
      ]);

      expect(totals, {
        PaymentMethod.cash: 15.5,
        PaymentMethod.paypal: 0.0,
        PaymentMethod.bizum: 7.0,
        PaymentMethod.unspecified: 4.0,
      });
    });

    test('totals add up to the overall revenue', () {
      final sales = [
        _sale(3.2, PaymentMethod.paypal),
        _sale(4.8, PaymentMethod.bizum),
        _sale(12, PaymentMethod.cash),
      ];
      final sum = PaymentMethod.totalsOf(sales).values.reduce((a, b) => a + b);
      expect(sum, closeTo(20, 1e-9));
    });

    test('returns all zeros for no sales', () {
      expect(PaymentMethod.totalsOf(const []).values, everyElement(0.0));
    });
  });

  group('Sale payment method', () {
    test('defaults to cash', () {
      final sale = Sale(date: DateTime(2026), totalAmount: 0, items: const []);
      expect(sale.paymentMethod, PaymentMethod.cash);
    });

    test('cart factory keeps the selected method', () {
      final sale = SaleFromCartFactory.create(
        date: DateTime(2026),
        products: const {},
        packs: const {},
        promotions: const {},
        paymentMethod: PaymentMethod.bizum,
      );
      expect(sale.paymentMethod, PaymentMethod.bizum);
    });
  });
}
