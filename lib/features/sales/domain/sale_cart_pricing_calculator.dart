import '../../inventory/domain/product.dart';
import '../../packs/domain/pack.dart';
import '../../promotions/domain/fixed_price_bundle_calculator.dart';
import '../../promotions/domain/promotion.dart';

class SaleCartPricingCalculator {
  const SaleCartPricingCalculator._();

  static double calculateItemTotal(
    Product targetProduct,
    Map<Product, int> cart,
    Map<int, Promotion> promotions,
  ) {
    final promotionId = targetProduct.promotionId;
    final promotion = promotionId == null ? null : promotions[promotionId];
    final quantity = cart[targetProduct]!;

    if (promotion == null) return targetProduct.price * quantity;

    final promotionProducts = cart.keys
        .where((product) => product.promotionId == promotionId)
        .toList();
    final combinedQuantity = promotionProducts.fold<int>(
      0,
      (total, product) => total + cart[product]!,
    );

    if (combinedQuantity < promotion.threshold) {
      return targetProduct.price * quantity;
    }

    if (promotion.type == 'percentage') {
      final discountedPrice =
          targetProduct.price * (1 - promotion.discountValue / 100);
      return discountedPrice * quantity;
    }

    if (promotion.type == 'bundle_fixed_price') {
      final itemTotals = FixedPriceBundleCalculator.calculateItemTotals(
        quantities: {
          for (final product in promotionProducts) product: cart[product]!,
        },
        priceOf: (product) => product.price,
        bundleSize: promotion.threshold,
        bundlePrice: promotion.discountValue,
      );
      return itemTotals[targetProduct] ?? 0.0;
    }

    return targetProduct.price * quantity;
  }

  static double calculateCartTotal({
    required Map<Product, int> products,
    required Map<Pack, int> packs,
    required Map<int, Promotion> promotions,
  }) {
    final productTotal = products.entries.fold<double>(
      0,
      (total, entry) =>
          total + calculateItemTotal(entry.key, products, promotions),
    );
    final packTotal = packs.entries.fold<double>(
      0,
      (total, entry) => total + entry.key.price * entry.value,
    );
    return productTotal + packTotal;
  }

  static int countItems({
    required Map<Product, int> products,
    required Map<Pack, int> packs,
  }) {
    final productCount = products.values.fold<int>(0, (sum, qty) => sum + qty);
    final packCount = packs.values.fold<int>(0, (sum, qty) => sum + qty);
    return productCount + packCount;
  }
}
