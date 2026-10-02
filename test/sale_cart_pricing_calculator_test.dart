import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';
import 'package:keepinventory/features/packs/domain/pack.dart';
import 'package:keepinventory/features/promotions/domain/promotion.dart';
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
    );

    expect(sale.date, saleDate);
    expect(sale.totalAmount, 24);
    expect(sale.items.single.historicalPrice, 9);
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
