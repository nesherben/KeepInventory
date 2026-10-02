import '../../inventory/domain/product.dart';
import '../../packs/domain/pack.dart';
import '../../promotions/domain/promotion.dart';
import 'sale.dart';
import 'sale_cart_pricing_calculator.dart';

class SaleFromCartFactory {
  const SaleFromCartFactory._();

  static Sale create({
    required DateTime date,
    required Map<Product, int> products,
    required Map<Pack, int> packs,
    required Map<int, Promotion> promotions,
  }) {
    final saleItems = products.entries.map((entry) {
      final product = entry.key;
      final quantity = entry.value;
      final promotion = product.promotionId == null
          ? null
          : promotions[product.promotionId];
      final subtotal = SaleCartPricingCalculator.calculateItemTotal(
        product,
        products,
        promotions,
      );

      return SaleItem(
        saleId: 0,
        productId: product.id!,
        productName: product.name,
        quantity: quantity,
        historicalPrice: subtotal / quantity,
        originalPrice: product.price,
        promotionId: product.promotionId,
        promoType: promotion?.type,
        promoThreshold: promotion?.threshold,
        promoDiscount: promotion?.discountValue,
      );
    }).toList();

    final salePacks = packs.entries
        .map(
          (entry) => SalePackItem(
            saleId: 0,
            packId: entry.key.id!,
            packName: entry.key.name,
            quantity: entry.value,
            historicalPrice: entry.key.price,
          ),
        )
        .toList();

    return Sale(
      date: date,
      totalAmount: SaleCartPricingCalculator.calculateCartTotal(
        products: products,
        packs: packs,
        promotions: promotions,
      ),
      items: saleItems,
      packItems: salePacks,
    );
  }
}
