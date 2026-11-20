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

    test('canDiscount blocks promoted products and combo units', () {
      final plain = _product(1, price: 5);
      final promoted = _product(2, price: 5, promotionId: 7);
      final orphanPromo = _product(3, price: 5, promotionId: 99);
      final promotions = {7: _promotion(id: 7, threshold: 2)};

      expect(SaleCartPricingCalculator.canDiscount(plain, promotions), isTrue);
      expect(
        SaleCartPricingCalculator.canDiscount(promoted, promotions),
        isFalse,
      );
      // Promoción borrada: ya no hay nada que mande
      expect(
        SaleCartPricingCalculator.canDiscount(orphanPromo, promotions),
        isTrue,
      );
      expect(
        SaleCartPricingCalculator.canDiscount(plain, promotions, comboUnits: 1),
        isFalse,
      );
    });

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
