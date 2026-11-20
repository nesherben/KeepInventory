import '../../inventory/domain/product.dart';
import '../../packs/domain/pack.dart';
import '../../promotions/domain/combo.dart';
import '../../promotions/domain/promotion.dart';
import 'manual_line_discount.dart';
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
    double adjustmentFactor = 1.0,
    Map<int, ManualLineDiscount> lineDiscounts = const {},
  }) {
    final pricing = SaleCartPricingCalculator.price(
      products: products,
      packs: packs,
      promotions: promotions,
      combos: combos,
      lineDiscounts: lineDiscounts,
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
      ManualLineDiscount? manual,
      double manualAmount = 0,
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
        manualDiscountType: manual?.type,
        // Importe: lo realmente descontado (puede quedar recortado al total)
        manualDiscountValue: manual == null
            ? null
            : (manual.type == ManualDiscountType.percent
                  ? manual.value
                  : manualAmount),
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
      final applied = pricing.appliedDiscounts[e.key.id] ?? 0;
      final itemTotal = SaleCartPricingCalculator.calculateItemTotal(
        e.key,
        pricing.loose,
        promotions,
      );
      saleItems.add(
        line(
          e.key,
          e.value,
          // Con descuento manual, el precio de la línea ya va rebajado
          applied > 0 ? roundToCents(itemTotal - applied) : itemTotal,
          manual: applied > 0 ? lineDiscounts[e.key.id] : null,
          manualAmount: applied,
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
      // Redondeado a céntimos para no guardar ruido de coma flotante
      totalAmount: (pricing.total * adjustmentFactor * 100).round() / 100,
      items: saleItems,
      packItems: salePacks,
      paymentMethod: paymentMethod,
      combos: saleCombos,
      adjustmentFactor: adjustmentFactor,
    );
  }
}
