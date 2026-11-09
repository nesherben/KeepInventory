import '../../inventory/domain/product.dart';
import '../../packs/domain/pack.dart';
import '../../promotions/domain/combo.dart';
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
    List<Combo> combos = const [],
    PaymentMethod paymentMethod = PaymentMethod.defaultMethod,
  }) {
    final pricing = SaleCartPricingCalculator.price(
      products: products,
      packs: packs,
      promotions: promotions,
      combos: combos,
    );
    final byId = {
      for (final p in products.keys)
        if (p.id != null) p.id!: p,
    };

    SaleItem line(
      Product product,
      int quantity,
      double subtotal, {
      int? saleComboId,
    }) {
      // La promo propia se congela también en las líneas de combo: si una
      // devolución rompe el combo, las unidades que quedan vuelven a su promo.
      final promotion = product.promotionId == null
          ? null
          : promotions[product.promotionId];
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
        saleComboId: saleComboId,
      );
    }

    // Los ids de SaleCombo son provisionales (índice); el datasource los
    // sustituye por los reales al guardar.
    final saleCombos = <SaleCombo>[];
    final saleItems = <SaleItem>[];
    final applications = pricing.combos.applications;
    for (var i = 0; i < applications.length; i++) {
      final application = applications[i];
      saleCombos.add(
        SaleCombo(
          id: i,
          comboId: application.combo.id,
          name: application.combo.name,
          price: application.combo.price,
          quantity: application.count,
          slots: application.combo.slots,
        ),
      );
      for (final e in application.usedUnits.entries) {
        saleItems.add(
          line(
            byId[e.key]!,
            e.value,
            application.lineTotals[e.key]!,
            saleComboId: i,
          ),
        );
      }
    }

    for (final e in pricing.loose.entries) {
      saleItems.add(
        line(
          e.key,
          e.value,
          SaleCartPricingCalculator.calculateItemTotal(
            e.key,
            pricing.loose,
            promotions,
          ),
        ),
      );
    }

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
      totalAmount: pricing.total,
      items: saleItems,
      packItems: salePacks,
      paymentMethod: paymentMethod,
      combos: saleCombos,
    );
  }
}
