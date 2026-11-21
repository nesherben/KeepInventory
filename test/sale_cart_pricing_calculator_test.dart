import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';
import 'package:keepinventory/features/packs/domain/pack.dart';
import 'package:keepinventory/features/promotions/domain/combo.dart';
import 'package:keepinventory/features/promotions/domain/promotion.dart';
import 'package:keepinventory/features/sales/domain/manual_line_discount.dart';
import 'package:keepinventory/features/sales/domain/sale_cart_pricing_calculator.dart';
import 'package:keepinventory/features/sales/domain/sale_from_cart_factory.dart';

void main() {
  group('SaleCartPricingCalculator', () {
    test(
      'uses regular prices when a promotion is missing or below threshold',
      () {
        final productWithoutPromotion = _product(1, price: 8);
        final promotedProduct = _product(2, price: 10, promotionId: 7);
        final promotion = _promotion(id: 7, threshold: 3);

        expect(
          SaleCartPricingCalculator.calculateItemTotal(
            productWithoutPromotion,
            {productWithoutPromotion: 2},
            {},
          ),
          16,
        );
        expect(
          SaleCartPricingCalculator.calculateItemTotal(
            promotedProduct,
            {promotedProduct: 2},
            {7: promotion},
          ),
          20,
        );
      },
    );

    test(
      'applies percentage discounts across products sharing the promotion',
      () {
        final first = _product(1, price: 10, promotionId: 7);
        final second = _product(2, price: 5, promotionId: 7);
        final cart = {first: 2, second: 1};
        final promotions = {7: _promotion(id: 7, threshold: 3)};

        expect(
          SaleCartPricingCalculator.calculateItemTotal(first, cart, promotions),
          16,
        );
        expect(
          SaleCartPricingCalculator.calculateItemTotal(
            second,
            cart,
            promotions,
          ),
          4,
        );
      },
    );

    test('uses fixed bundle pricing for checkout totals', () {
      final expensive = _product(1, price: 10, promotionId: 7);
      final cheap = _product(2, price: 5, promotionId: 7);
      final cart = {expensive: 2, cheap: 1};
      final promotions = {
        7: _promotion(
          id: 7,
          type: 'bundle_fixed_price',
          threshold: 2,
          discount: 12,
        ),
      };

      expect(
        SaleCartPricingCalculator.calculateItemTotal(
          expensive,
          cart,
          promotions,
        ),
        12,
      );
      expect(
        SaleCartPricingCalculator.calculateItemTotal(cheap, cart, promotions),
        5,
      );
    });

    test('calculates cart total and item count including packs', () {
      final product = _product(1, price: 4);
      final pack = _pack(1, price: 6);

      expect(
        SaleCartPricingCalculator.calculateCartTotal(
          products: {product: 2},
          packs: {pack: 3},
          promotions: {},
        ),
        26,
      );
      expect(
        SaleCartPricingCalculator.countItems(
          products: {product: 2},
          packs: {pack: 3},
        ),
        5,
      );
    });
  });

  group('manual line discounts', () {
    test('percentage discount lowers the line total and is reported', () {
      final shirt = _product(1, price: 12);

      final pricing = SaleCartPricingCalculator.price(
        products: {shirt: 1},
        packs: {},
        promotions: {},
        lineDiscounts: {1: const ManualLineDiscount.percent(10)},
      );

      expect(pricing.total, 10.8);
      expect(pricing.totalOf(shirt), 10.8);
      expect(pricing.appliedDiscounts, {1: 1.2});
      expect(pricing.discountTotal, 1.2);
    });

    test('amount discount applies to the whole line, not per unit', () {
      final mug = _product(1, price: 10);

      final pricing = SaleCartPricingCalculator.price(
        products: {mug: 3},
        packs: {},
        promotions: {},
        lineDiscounts: {1: const ManualLineDiscount.amount(2)},
      );

      expect(pricing.total, 28);
    });

    test('line total is clamped to zero', () {
      final mug = _product(1, price: 10);

      final pricing = SaleCartPricingCalculator.price(
        products: {mug: 1},
        packs: {},
        promotions: {},
        lineDiscounts: {1: const ManualLineDiscount.amount(99)},
      );

      expect(pricing.total, 0);
      expect(pricing.appliedDiscounts, {1: 10});
    });

    test('a promoted product ignores the manual discount', () {
      final promoted = _product(1, price: 10, promotionId: 7);

      final pricing = SaleCartPricingCalculator.price(
        products: {promoted: 3},
        packs: {},
        promotions: {7: _promotion(id: 7, threshold: 3)},
        lineDiscounts: {1: const ManualLineDiscount.percent(50)},
      );

      // Manda la promoción (20 % desde 3 uds.): 3 × 8 = 24
      expect(pricing.total, 24);
      expect(pricing.appliedDiscounts, isEmpty);
    });

    test('a product inside a combo ignores the manual discount', () {
      final a = _product(1, price: 8);
      final b = _product(2, price: 6);
      const combo = Combo(
        id: 1,
        name: 'A + B',
        price: 10,
        slots: [
          ComboSlot(name: 'a', productIds: [1]),
          ComboSlot(name: 'b', productIds: [2]),
        ],
      );

      final pricing = SaleCartPricingCalculator.price(
        products: {a: 1, b: 1},
        packs: {},
        promotions: {},
        combos: [combo],
        lineDiscounts: {1: const ManualLineDiscount.percent(50)},
      );

      expect(pricing.total, 10);
      expect(pricing.appliedDiscounts, isEmpty);
    });

    test('canDiscount only blocks an ACTIVE promotion or combo units', () {
      final plain = _product(1, price: 5);
      final promoted = _product(2, price: 5, promotionId: 7);
      final orphanPromo = _product(3, price: 5, promotionId: 99);
      final promotions = {7: _promotion(id: 7, threshold: 2)};

      expect(SaleCartPricingCalculator.canDiscount(plain, promotions), isTrue);
      // Promoción asignada pero sin cumplir su condición (1 de 2): se puede
      expect(
        SaleCartPricingCalculator.canDiscount(
          promoted,
          promotions,
          loose: {promoted: 1},
        ),
        isTrue,
      );
      // Condición cumplida (2 de 2): la promoción manda
      expect(
        SaleCartPricingCalculator.canDiscount(
          promoted,
          promotions,
          loose: {promoted: 2},
        ),
        isFalse,
      );
      // Promoción borrada: ya no hay nada que mande
      expect(
        SaleCartPricingCalculator.canDiscount(
          orphanPromo,
          promotions,
          loose: {orphanPromo: 5},
        ),
        isTrue,
      );
      expect(
        SaleCartPricingCalculator.canDiscount(plain, promotions, comboUnits: 1),
        isFalse,
      );
    });

    test('promotion counts units across products sharing it (mix & match)', () {
      final a = _product(1, price: 10, promotionId: 7);
      final b = _product(2, price: 10, promotionId: 7);
      final promotions = {7: _promotion(id: 7, threshold: 3)};

      expect(
        SaleCartPricingCalculator.isPromotionActive(a, {a: 2}, promotions),
        isFalse,
      );
      // 2 de A + 1 de B = 3: se activa para los dos
      expect(
        SaleCartPricingCalculator.isPromotionActive(a, {
          a: 2,
          b: 1,
        }, promotions),
        isTrue,
      );
      expect(
        SaleCartPricingCalculator.isPromotionActive(b, {
          a: 2,
          b: 1,
        }, promotions),
        isTrue,
      );
    });

    test('a manual discount applies while the assigned promotion is unmet', () {
      final promoted = _product(1, price: 10, promotionId: 7);
      final promotions = {7: _promotion(id: 7, threshold: 3)};

      final pricing = SaleCartPricingCalculator.price(
        products: {promoted: 2},
        packs: {},
        promotions: promotions,
        lineDiscounts: {1: const ManualLineDiscount.percent(10)},
      );

      // 2 uds. a 10 € (sin promo, aún) − 10 % = 18 €
      expect(pricing.total, 18);
      expect(pricing.appliedDiscounts, {1: 2});
    });

    test(
      'the manual discount is cancelled the instant the promotion kicks in',
      () {
        final promoted = _product(1, price: 10, promotionId: 7);
        final promotions = {7: _promotion(id: 7, threshold: 3)};
        const discounts = {1: ManualLineDiscount.percent(10)};

        // Con 2 uds. se puede; con 3 la promoción (−20 %) manda y el manual se ignora
        final unmet = SaleCartPricingCalculator.price(
          products: {promoted: 2},
          packs: {},
          promotions: promotions,
          lineDiscounts: discounts,
        );
        final met = SaleCartPricingCalculator.price(
          products: {promoted: 3},
          packs: {},
          promotions: promotions,
          lineDiscounts: discounts,
        );

        expect(unmet.appliedDiscounts, isNotEmpty);
        expect(met.total, 24); // 3 × 10 − 20 % de la promoción
        expect(met.appliedDiscounts, isEmpty);

        // …y la pantalla lo detecta para quitarlo del carrito
        expect(
          SaleCartPricingCalculator.lineDiscountsToDrop(
            products: {promoted: 2},
            packs: {},
            promotions: promotions,
            discountedIds: {1},
          ),
          isEmpty,
        );
        expect(
          SaleCartPricingCalculator.lineDiscountsToDrop(
            products: {promoted: 3},
            packs: {},
            promotions: promotions,
            discountedIds: {1},
          ).map((p) => p.id),
          [1],
        );
      },
    );

    test('lineDiscountsToDrop returns products that gained a combo', () {
      final a = _product(1, price: 8);
      final b = _product(2, price: 6);
      const combo = Combo(
        id: 1,
        name: 'A + B',
        price: 10,
        slots: [
          ComboSlot(name: 'a', productIds: [1]),
          ComboSlot(name: 'b', productIds: [2]),
        ],
      );

      // Solo A: sin combo, su descuento sigue valiendo
      expect(
        SaleCartPricingCalculator.lineDiscountsToDrop(
          products: {a: 1},
          packs: {},
          promotions: {},
          combos: [combo],
          discountedIds: {1},
        ),
        isEmpty,
      );
      // Al añadir B se forma el combo: manda el combo y el descuento de A cae
      final dropped = SaleCartPricingCalculator.lineDiscountsToDrop(
        products: {a: 1, b: 1},
        packs: {},
        promotions: {},
        combos: [combo],
        discountedIds: {1},
      );
      expect(dropped.map((p) => p.id), [1]);
    });

    test('lineDiscountsToDrop ignores products without a discount', () {
      final promoted = _product(1, price: 10, promotionId: 7);
      final plain = _product(2, price: 10);

      final dropped = SaleCartPricingCalculator.lineDiscountsToDrop(
        products: {promoted: 1, plain: 1},
        packs: {},
        promotions: {7: _promotion(id: 7, threshold: 2)},
        discountedIds: {2},
      );

      expect(dropped, isEmpty);
    });

    test('a tiny percentage never discounts below a cent', () {
      final cheap = _product(1, price: 1);

      final pricing = SaleCartPricingCalculator.price(
        products: {cheap: 1},
        packs: {},
        promotions: {},
        lineDiscounts: {1: const ManualLineDiscount.percent(0.01)},
      );

      expect(pricing.total, 1);
      expect(pricing.appliedDiscounts, isEmpty);
    });

    // "3 por 15 €": la 4.ª unidad queda fuera del lote y admite descuento manual
    test('units outside a fixed-price bundle admit a manual discount', () {
      final shirt = _product(1, price: 10, promotionId: 7);
      final promotions = {
        7: _promotion(
          id: 7,
          type: 'bundle_fixed_price',
          threshold: 3,
          discount: 15,
        ),
      };

      // Con 4 uds. el lote cubre 3 y queda 1 fuera
      expect(
        SaleCartPricingCalculator.uncoveredUnits(shirt, {shirt: 4}, promotions),
        1,
      );
      expect(
        SaleCartPricingCalculator.canDiscount(
          shirt,
          promotions,
          loose: {shirt: 4},
        ),
        isTrue,
      );
      expect(
        SaleCartPricingCalculator.discountBase(shirt, {shirt: 4}, promotions),
        10,
      );
      // Con 3 (o 6) uds. el lote las cubre todas: no se ofrece
      for (final qty in [3, 6]) {
        expect(
          SaleCartPricingCalculator.uncoveredUnits(shirt, {
            shirt: qty,
          }, promotions),
          0,
        );
        expect(
          SaleCartPricingCalculator.canDiscount(
            shirt,
            promotions,
            loose: {shirt: qty},
          ),
          isFalse,
        );
      }
    });

    test('the manual discount only acts on the units outside the bundle', () {
      final shirt = _product(1, price: 10, promotionId: 7);
      final promotions = {
        7: _promotion(
          id: 7,
          type: 'bundle_fixed_price',
          threshold: 3,
          discount: 15,
        ),
      };

      final pricing = SaleCartPricingCalculator.price(
        products: {shirt: 4},
        packs: {},
        promotions: promotions,
        // 20 % de la unidad suelta (10 €), no de la línea entera
        lineDiscounts: {1: const ManualLineDiscount.percent(20)},
      );

      // Lote de 3 = 15 € + la 4.ª (10 €) − 2 € = 23 €
      expect(pricing.total, 23);
      expect(pricing.appliedDiscounts, {1: 2});
    });

    test('a manual amount cannot exceed the units outside the bundle', () {
      final shirt = _product(1, price: 10, promotionId: 7);
      final promotions = {
        7: _promotion(
          id: 7,
          type: 'bundle_fixed_price',
          threshold: 3,
          discount: 15,
        ),
      };

      final pricing = SaleCartPricingCalculator.price(
        products: {shirt: 4},
        packs: {},
        promotions: promotions,
        lineDiscounts: {1: const ManualLineDiscount.amount(50)},
      );

      // Máximo 10 € (la unidad suelta): el lote no se toca
      expect(pricing.total, 15);
      expect(pricing.appliedDiscounts, {1: 10});
    });

    test('a percentage promotion covers every unit: no manual discount', () {
      final shirt = _product(1, price: 10, promotionId: 7);
      final promotions = {7: _promotion(id: 7, threshold: 3)};

      expect(
        SaleCartPricingCalculator.uncoveredUnits(shirt, {shirt: 4}, promotions),
        0,
      );
      final pricing = SaleCartPricingCalculator.price(
        products: {shirt: 4},
        packs: {},
        promotions: promotions,
        lineDiscounts: {1: const ManualLineDiscount.percent(50)},
      );
      expect(pricing.appliedDiscounts, isEmpty);
    });

    test('mix & match: the leftover goes to the cheapest products', () {
      final dear = _product(1, price: 10, promotionId: 7);
      final cheap = _product(2, price: 5, promotionId: 7);
      final promotions = {
        7: _promotion(
          id: 7,
          type: 'bundle_fixed_price',
          threshold: 3,
          discount: 15,
        ),
      };
      final loose = {dear: 2, cheap: 2};

      // Los lotes cogen las unidades más caras: la suelta es una barata
      expect(
        SaleCartPricingCalculator.uncoveredUnits(dear, loose, promotions),
        0,
      );
      expect(
        SaleCartPricingCalculator.uncoveredUnits(cheap, loose, promotions),
        1,
      );
    });

    test('adding or removing units moves the discount in and out of scope', () {
      final shirt = _product(1, price: 10, promotionId: 7);
      final promotions = {
        7: _promotion(
          id: 7,
          type: 'bundle_fixed_price',
          threshold: 3,
          discount: 15,
        ),
      };
      List<int?> toDrop(int qty) =>
          SaleCartPricingCalculator.lineDiscountsToDrop(
            products: {shirt: qty},
            packs: {},
            promotions: promotions,
            discountedIds: {1},
          ).map((p) => p.id).toList();

      expect(toDrop(2), isEmpty); // sin lote aún
      expect(toDrop(3), [1]); // el lote cubre todas: se cancela
      expect(toDrop(4), isEmpty); // la 4.ª queda fuera: vuelve a valer
    });

    test('factory freezes the discounted price and the discount fields', () {
      final shirt = _product(1, price: 12);

      final sale = SaleFromCartFactory.create(
        date: DateTime(2026, 11, 1),
        products: {shirt: 3},
        packs: {},
        promotions: {},
        lineDiscounts: {1: const ManualLineDiscount.percent(10)},
      );

      final item = sale.items.single;
      // 3 × 12 = 36 − 10 % = 32,40 en total de línea
      expect(sale.totalAmount, 32.4);
      expect(item.historicalPrice * item.quantity, closeTo(32.4, 1e-9));
      expect(item.originalPrice, 12);
      expect(item.manualDiscountType, ManualDiscountType.percent);
      expect(item.manualDiscountValue, 10);
      expect(item.hasManualDiscount, isTrue);
    });

    test('factory stores the real amount when it is clamped to the line', () {
      final mug = _product(1, price: 10);

      final sale = SaleFromCartFactory.create(
        date: DateTime(2026, 11, 1),
        products: {mug: 1},
        packs: {},
        promotions: {},
        lineDiscounts: {1: const ManualLineDiscount.amount(99)},
      );

      expect(sale.totalAmount, 0);
      expect(sale.items.single.manualDiscountType, ManualDiscountType.amount);
      expect(sale.items.single.manualDiscountValue, 10);
    });

    test('lines without a discount keep the discount fields empty', () {
      final shirt = _product(1, price: 12);

      final sale = SaleFromCartFactory.create(
        date: DateTime(2026, 11, 1),
        products: {shirt: 1},
        packs: {},
        promotions: {},
      );

      expect(sale.items.single.manualDiscountType, isNull);
      expect(sale.items.single.manualDiscountValue, isNull);
      expect(sale.items.single.hasManualDiscount, isFalse);
    });
  });

  test('factory preserves sale prices, promotion metadata, and pack lines', () {
    final product = _product(1, price: 10, promotionId: 7);
    final pack = _pack(2, price: 6);
    final promotion = _promotion(id: 7, threshold: 2, discount: 10);
    final saleDate = DateTime(2026, 10, 2);

    final sale = SaleFromCartFactory.create(
      date: saleDate,
      products: {product: 2},
      packs: {pack: 1},
      promotions: {7: promotion},
      adjustmentFactor: 0.8,
    );

    expect(sale.date, saleDate);
    expect(sale.totalAmount, closeTo(19.2, 1e-9));
    expect(sale.adjustmentFactor, 0.8);
    expect(sale.items.single.historicalPrice, 9);
    expect(sale.items.single.originalPrice, 10);
    expect(sale.items.single.promoType, 'percentage');
    expect(sale.items.single.promoThreshold, 2);
    expect(sale.items.single.promoDiscount, 10);
    expect(sale.packItems.single.packId, 2);
    expect(sale.packItems.single.quantity, 1);
  });
}

Product _product(int id, {required double price, int? promotionId}) {
  return Product(
    id: id,
    name: 'Product $id',
    units: 10,
    price: price,
    cost: price / 2,
    promotionId: promotionId,
  );
}

Pack _pack(int id, {required double price}) {
  return Pack(
    id: id,
    name: 'Pack $id',
    price: price,
    units: 10,
    items: const [],
  );
}

Promotion _promotion({
  required int id,
  String type = 'percentage',
  required int threshold,
  double discount = 20,
}) {
  return Promotion(
    id: id,
    name: 'Offer',
    type: type,
    threshold: threshold,
    discountValue: discount,
  );
}
