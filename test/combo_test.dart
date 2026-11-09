import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';
import 'package:keepinventory/features/promotions/domain/combo.dart';
import 'package:keepinventory/features/promotions/domain/combo_matcher.dart';
import 'package:keepinventory/features/promotions/domain/promotion.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:keepinventory/features/sales/domain/sale_cart_pricing_calculator.dart';
import 'package:keepinventory/features/sales/domain/sale_from_cart_factory.dart';
import 'package:keepinventory/features/sales/domain/sale_refund_calculator.dart';

Product _p(int id, String name, double price, {int? promo}) => Product(
  id: id,
  name: name,
  units: 50,
  price: price,
  cost: 1,
  promotionId: promo,
);

// Teclados (1, 2) a 6 € y 7 €, ratón (3) a 5 €
final keyboardA = _p(1, 'Teclado A', 6);
final keyboardB = _p(2, 'Teclado B', 7);
final mouse = _p(3, 'Ratón', 5);
final cable = _p(4, 'Cable', 2);

const combo = Combo(
  id: 1,
  name: 'Teclado + Ratón',
  price: 10,
  slots: [
    ComboSlot(name: 'Teclado', productIds: [1, 2]),
    ComboSlot(name: 'Ratón', productIds: [3]),
  ],
);

final prices = {1: 6.0, 2: 7.0, 3: 5.0, 4: 2.0};

ComboMatchResult _match(Map<int, int> quantities, [List<Combo>? combos]) =>
    ComboMatcher.match(
      combos: combos ?? const [combo],
      quantities: quantities,
      priceOf: (id) => prices[id]!,
    );

double _cart(Map<Product, int> products, {Map<int, Promotion>? promos}) =>
    SaleCartPricingCalculator.calculateCartTotal(
      products: products,
      packs: const {},
      promotions: promos ?? const {},
      combos: const [combo],
    );

void main() {
  group('ComboMatcher', () {
    test('keyboard + mouse makes one combo', () {
      final r = _match({1: 1, 3: 1});
      expect(r.applications.single.count, 1);
      expect(r.applications.single.total, closeTo(10, 1e-9));
      expect(r.remaining, isEmpty);
    });

    test('two keyboards alone are not a combo', () {
      final r = _match({1: 2});
      expect(r.applications, isEmpty);
      expect(r.remaining, {1: 2});
    });

    test('repeats per complete combo and leaves the rest', () {
      final r = _match({1: 2, 2: 1, 3: 2});
      expect(r.applications.single.count, 2);
      // Usa los teclados más caros primero: B (7) y uno de A (6)
      expect(r.applications.single.usedUnits, {2: 1, 1: 1, 3: 2});
      expect(r.remaining, {1: 1});
    });

    test('splits the price in exact cents, proportional to list price', () {
      final three = Combo(
        name: 'x',
        price: 10,
        slots: const [
          ComboSlot(name: 'a', productIds: [1]),
          ComboSlot(name: 'b', productIds: [3]),
          ComboSlot(name: 'c', productIds: [4]),
        ],
      );
      final r = _match({1: 1, 3: 1, 4: 1}, [three]);
      final totals = r.applications.single.lineTotals;
      expect(totals.values.fold(0.0, (t, v) => t + v), closeTo(10, 1e-9));
      for (final v in totals.values) {
        expect((v * 100).roundToDouble(), closeTo(v * 100, 1e-6));
      }
      expect(totals[1]!, greaterThan(totals[3]!));
    });

    test('slot quantity: 2 mice + 1 keyboard', () {
      const twoMice = Combo(
        name: '2 ratones + teclado',
        price: 14,
        slots: [
          ComboSlot(name: 'Ratón', quantity: 2, productIds: [3]),
          ComboSlot(name: 'Teclado', productIds: [1]),
        ],
      );
      expect(_match({3: 1, 1: 1}, [twoMice]).applications, isEmpty);
      expect(_match({3: 2, 1: 1}, [twoMice]).applications.single.count, 1);
      expect(_match({3: 5, 1: 3}, [twoMice]).applications.single.count, 2);
    });

    test('hint lists the missing slot when half a combo is in the cart', () {
      final hint = _match({1: 1}).hints.single;
      expect(hint.missing.map((s) => s.name), ['Ratón']);
      expect(hint.filled, 1);
      expect(_match({1: 1, 3: 1}).hints, isEmpty);
      expect(_match({4: 1}).hints, isEmpty);
    });
  });

  group('Cart pricing with combos', () {
    test('keyboard + mouse = 10 instead of 11', () {
      expect(_cart({keyboardA: 1, mouse: 1}), closeTo(10, 1e-9));
    });

    test('two keyboards stay at full price', () {
      expect(_cart({keyboardA: 2}), closeTo(12, 1e-9));
    });

    test('leftover units go at their normal price', () {
      // 2 teclados A + 1 ratón = combo (10) + teclado (6)
      expect(_cart({keyboardA: 2, mouse: 1}), closeTo(16, 1e-9));
    });

    test('combo wins over own promotion; leftovers keep the promotion', () {
      final mousePromo = _p(3, 'Ratón', 5, promo: 9);
      final promos = {
        9: Promotion(
          id: 9,
          name: '10%',
          type: 'percentage',
          threshold: 1,
          discountValue: 10,
        ),
      };
      // 1 combo (10) + 1 ratón suelto con 10 % (4,5)
      expect(
        _cart({keyboardA: 1, mousePromo: 2}, promos: promos),
        closeTo(14.5, 1e-9),
      );
    });

    test('saving and per-product totals', () {
      final pricing = SaleCartPricingCalculator.price(
        products: {keyboardA: 1, mouse: 1, cable: 1},
        packs: const {},
        promotions: const {},
        combos: const [combo],
      );
      expect(pricing.comboSaving, closeTo(1, 1e-9));
      expect(pricing.totalOf(cable), 2);
      expect(pricing.comboUnitsOf(mouse), 1);
      expect(pricing.total, closeTo(12, 1e-9));
    });
  });

  group('Sale with combos', () {
    Sale sale(Map<Product, int> products) => SaleFromCartFactory.create(
      date: DateTime(2026),
      products: products,
      packs: const {},
      promotions: const {},
      combos: const [combo],
    );

    test('splits lines and keeps line sum == total', () {
      final s = sale({keyboardA: 2, mouse: 1});
      expect(s.combos.single.quantity, 1);
      expect(s.items.length, 3); // A en combo + ratón en combo + A suelto
      final sum = s.items.fold<double>(
        0,
        (t, i) => t + i.historicalPrice * i.quantity,
      );
      expect(sum, closeTo(s.totalAmount, 1e-9));
      expect(s.totalAmount, closeTo(16, 1e-9));
      expect(s.items.where((i) => i.saleComboId != null).length, 2);
    });

    // Las devoluciones usan los ids reales; aquí simulamos ya guardada
    Map<SaleItem, int> quantities(Sale s) => {
      for (final i in s.items) i: i.quantity,
    };

    double refund(Sale s, Map<SaleItem, int> kept) =>
        SaleRefundCalculator.calculateRefundAmount(
          originalItemQuantities: quantities(s),
          keptItemQuantities: kept,
          originalPackQuantities: const {},
          keptPackQuantities: const {},
          combos: s.combos,
        );

    test('returning the keyboard of a combo refunds 10 - 5 = 5', () {
      final s = sale({keyboardA: 1, mouse: 1});
      final kept = {
        for (final i in s.items) i: i.productId == mouse.id ? 1 : 0,
      };
      expect(refund(s, kept), closeTo(5, 1e-9));
    });

    test('returning the whole combo refunds its price', () {
      final s = sale({keyboardA: 1, mouse: 1, cable: 1});
      final kept = {
        for (final i in s.items) i: i.productId == cable.id ? 1 : 0,
      };
      expect(refund(s, kept), closeTo(10, 1e-9));
    });

    test('a combo can re-form with leftover units', () {
      // 2 teclados A + 1 ratón: combo + teclado suelto. Devolver el teclado
      // del combo deja otro teclado + ratón → sigue habiendo combo.
      final s = sale({keyboardA: 2, mouse: 1});
      final comboKeyboard = s.items.firstWhere(
        (i) => i.saleComboId != null && i.productId == keyboardA.id,
      );
      final kept = {
        for (final i in s.items) i: i == comboKeyboard ? 0 : i.quantity,
      };
      // Queda teclado + ratón = combo (10): se devuelven 16 - 10 = 6, igual
      // que si se hubiera marcado la línea del teclado suelto.
      expect(refund(s, kept), closeTo(6, 1e-9));

      final looseKeyboard = s.items.firstWhere(
        (i) => i.saleComboId == null && i.productId == keyboardA.id,
      );
      final keptOther = {
        for (final i in s.items) i: i == looseKeyboard ? 0 : i.quantity,
      };
      expect(refund(s, keptOther), closeTo(6, 1e-9));
    });

    test('kept line values add up to the kept total', () {
      final s = sale({keyboardA: 2, mouse: 1});
      final comboKeyboard = s.items.firstWhere(
        (i) => i.saleComboId != null && i.productId == keyboardA.id,
      );
      final result = SaleRefundCalculator.calculateKeptValue(
        originalItemQuantities: quantities(s),
        keptItemQuantities: {
          for (final i in s.items) i: i == comboKeyboard ? 0 : i.quantity,
        },
        keptPackQuantities: const {},
        combos: s.combos,
      );
      expect(result.total, closeTo(10, 1e-9));
      expect(result.comboCounts[0], 1);
    });

    test('nothing returned refunds nothing', () {
      final s = sale({keyboardA: 1, mouse: 1});
      expect(refund(s, quantities(s)), 0);
    });

    test('definition survives a JSON round trip', () {
      final slots = Combo.decodeDefinition(combo.encodeDefinition());
      expect(slots.map((s) => s.productIds), [
        [1, 2],
        [3],
      ]);
    });
  });

  group('Partial refunds in several steps', () {
    Sale sale(Map<Product, int> products) => SaleFromCartFactory.create(
      date: DateTime(2026),
      products: products,
      packs: const {},
      promotions: const {},
      combos: const [combo],
    );

    /// Aplica una devolución y devuelve (importe, venta resultante).
    (double, Sale) refund(Sale s, Map<SaleItem, int> toRefund) {
      final amount = SaleRefundCalculator.calculateRefundAmount(
        originalItemQuantities: {for (final i in s.items) i: i.quantity},
        keptItemQuantities: {
          for (final i in s.items) i: i.quantity - (toRefund[i] ?? 0),
        },
        originalPackQuantities: const {},
        keptPackQuantities: const {},
        combos: s.combos,
      );
      final rest = SaleRefundCalculator.remainingAfterRefund(
        sale: s,
        itemsToRefund: toRefund,
      );
      return (
        amount,
        Sale(
          date: s.date,
          totalAmount: s.totalAmount - amount,
          items: rest.items,
          combos: rest.combos,
        ),
      );
    }

    double linesSum(Sale s) =>
        s.items.fold(0.0, (t, i) => t + i.historicalPrice * i.quantity);

    test('combo + loose mouse: return combo mouse, then keyboard', () {
      // Teclado A (6) + Ratón (5) en combo = 10, más un ratón suelto (5)
      final s0 = sale({keyboardA: 1, mouse: 2});
      expect(s0.totalAmount, closeTo(15, 1e-9));

      final comboMouse = s0.items.firstWhere(
        (i) => i.saleComboId != null && i.productId == mouse.id,
      );
      final (r1, s1) = refund(s0, {comboMouse: 1});
      expect(r1, closeTo(5, 1e-9)); // el ratón suelto rehace el combo
      expect(s1.combos.single.quantity, 1);
      expect(linesSum(s1), closeTo(10, 1e-9));
      // Ninguna línea mezcla precio de combo y suelto
      expect(s1.items.every((i) => i.saleComboId != null), isTrue);

      final keyboard = s1.items.firstWhere((i) => i.productId == keyboardA.id);
      final (r2, s2) = refund(s1, {keyboard: 1});
      expect(r2, closeTo(5, 1e-9)); // queda el ratón a precio normal
      expect(s2.combos, isEmpty);
      expect(s2.items.single.saleComboId, isNull);
      expect(linesSum(s2), closeTo(5, 1e-9));
    });

    test('a broken combo leaves its lines loose', () {
      final s0 = sale({keyboardA: 1, mouse: 1});
      final m = s0.items.firstWhere((i) => i.productId == mouse.id);
      final (r1, s1) = refund(s0, {m: 1});
      expect(r1, closeTo(4, 1e-9)); // 10 - teclado a precio normal (6)
      expect(s1.combos, isEmpty);
      expect(s1.items.single.saleComboId, isNull);
      expect(s1.items.single.historicalPrice, closeTo(6, 1e-9));
    });

    test('slot quantity 2: lines still add up after a partial refund', () {
      const twoMice = Combo(
        id: 2,
        name: '2 ratones + teclado',
        price: 14,
        slots: [
          ComboSlot(name: 'Ratón', quantity: 2, productIds: [3]),
          ComboSlot(name: 'Teclado A', productIds: [1]),
        ],
      );
      final s0 = SaleFromCartFactory.create(
        date: DateTime(2026),
        products: {mouse: 5, keyboardA: 2},
        packs: const {},
        promotions: const {},
        combos: const [twoMice],
      );
      // 2 combos (28) + 1 ratón suelto (5)
      expect(s0.totalAmount, closeTo(33, 1e-9));
      expect(linesSum(s0), closeTo(33, 1e-9));
      final k = s0.items.firstWhere((i) => i.productId == keyboardA.id);
      final (r1, s1) = refund(s0, {k: 1});
      // Queda 1 teclado: 1 combo (14) + 3 ratones sueltos (15) = 29
      expect(s1.combos.single.quantity, 1);
      expect(linesSum(s1), closeTo(29, 1e-9));
      expect(r1, closeTo(4, 1e-9));
    });

    test('free combo splits 0 and adds up', () {
      const free = Combo(
        id: 3,
        name: 'Regalo',
        price: 0,
        slots: [
          ComboSlot(name: 'a', productIds: [1]),
          ComboSlot(name: 'b', productIds: [3]),
        ],
      );
      final r = ComboMatcher.match(
        combos: const [free],
        quantities: {1: 1, 3: 1},
        priceOf: (id) => prices[id]!,
      );
      expect(r.applications.single.total, 0);
    });
  });

  group('Category slots', () {
    // Polaroids (10, 11) a 6 y 7 €; prints A5 (20, 21) a 5 €
    final catPrices = {10: 6.0, 11: 7.0, 20: 5.0, 21: 5.0};
    const anyPolaroidAnyPrint = Combo(
      id: 9,
      name: 'Polaroid + Print',
      price: 10,
      slots: [
        ComboSlot(name: 'Polaroid', productIds: [10, 11], categoryId: 1),
        ComboSlot(name: 'Print A5', productIds: [20, 21], categoryId: 2),
      ],
    );

    test('any polaroid + any print makes a combo; two polaroids do not', () {
      final r = ComboMatcher.match(
        combos: const [anyPolaroidAnyPrint],
        quantities: {10: 1, 11: 1, 21: 1},
        priceOf: (id) => catPrices[id]!,
      );
      expect(r.applications.single.count, 1);
      // Usa la polaroid más cara (11) y deja la otra suelta
      expect(r.applications.single.usedUnits, {11: 1, 21: 1});
      expect(r.remaining, {10: 1});

      final none = ComboMatcher.match(
        combos: const [anyPolaroidAnyPrint],
        quantities: {10: 1, 11: 1},
        priceOf: (id) => catPrices[id]!,
      );
      expect(none.applications, isEmpty);
    });

    test('category slot survives the JSON snapshot', () {
      final slots = Combo.decodeDefinition(
        anyPolaroidAnyPrint.encodeDefinition(),
      );
      expect(slots.first.categoryId, 1);
      expect(slots.first.isCategory, isTrue);
      expect(slots.first.productIds, [10, 11]);
    });
  });
}
