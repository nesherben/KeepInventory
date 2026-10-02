import 'sale.dart';
import '../../promotions/domain/fixed_price_bundle_calculator.dart';

class SaleRefundCalculator {
  const SaleRefundCalculator._();

  static double calculateRemainingCartValue({
    required Map<SaleItem, int> originalItemQuantities,
    required Map<SaleItem, int> keptItemQuantities,
    required Map<SalePackItem, int> keptPackQuantities,
  }) {
    var totalValue = 0.0;

    for (final entry in keptPackQuantities.entries) {
      totalValue += entry.key.historicalPrice * entry.value;
    }

    // Agrupamos con las cantidades ORIGINALES para detectar también
    // los items que se han devuelto por completo.
    final itemsByPromotion = <int?, List<SaleItem>>{};
    for (final entry in originalItemQuantities.entries) {
      if (entry.value > 0) {
        itemsByPromotion
            .putIfAbsent(entry.key.promotionId, () => [])
            .add(entry.key);
      }
    }

    for (final entry in itemsByPromotion.entries) {
      final items = entry.value;

      final keptItems = items
          .where((i) => (keptItemQuantities[i] ?? 0) > 0)
          .toList();
      if (keptItems.isEmpty) continue;

      // Sin promoción, o grupo sin ningún cambio: se conserva lo cobrado.
      final isAffected = items.any(
        (i) => (keptItemQuantities[i] ?? 0) < (originalItemQuantities[i] ?? 0),
      );
      if (entry.key == null || !isAffected) {
        totalValue += _paidValue(
          keptItems,
          keptItemQuantities,
          originalItemQuantities,
        );
        continue;
      }

      // A partir de aquí: grupo con promoción afectado por la devolución.
      final promotion = items.first;
      final type = promotion.promoType;
      final threshold = promotion.promoThreshold;
      final discount = promotion.promoDiscount;
      if (type == null || threshold == null || discount == null) {
        totalValue += _fullPriceValue(keptItems, keptItemQuantities);
        continue;
      }

      final quantity = keptItems.fold<int>(
        0,
        (total, item) => total + keptItemQuantities[item]!,
      );

      if (quantity < threshold) {
        // Ya no cumple la promoción: precio completo.
        totalValue += _fullPriceValue(keptItems, keptItemQuantities);
      } else if (type == 'percentage') {
        totalValue += keptItems.fold<double>(
          0,
          (total, item) =>
              total +
              item.refundUnitPrice *
                  (1 - discount / 100) *
                  keptItemQuantities[item]!,
        );
      } else if (type == 'bundle_fixed_price') {
        totalValue += _fixedBundleValue(
          keptItems,
          keptItemQuantities,
          threshold,
          discount,
        );
      } else {
        // Tipo de promoción desconocido: no perdemos el valor de las líneas.
        totalValue += _paidValue(
          keptItems,
          keptItemQuantities,
          originalItemQuantities,
        );
      }
    }

    return totalValue;
  }

  /// Lo que realmente se cobró por las unidades que se conservan.
  static double _paidValue(
    List<SaleItem> items,
    Map<SaleItem, int> kept,
    Map<SaleItem, int> original,
  ) {
    return items.fold<double>(
      0,
      (total, item) => total + _paidValueOf(item, kept[item]!, original[item]!),
    );
  }

  /// ⚠️ ADAPTAR: sustituye `lineTotal` por el campo de SaleItem donde
  /// guardes el total cobrado de la línea (con descuento ya aplicado).
  /// Se prorratea por si se conservan menos unidades que las originales.
  static double _paidValueOf(SaleItem item, int keptQty, int originalQty) {
    if (originalQty == 0) return 0;
    return item.refundUnitPrice / originalQty * keptQty;
  }

  static double _fullPriceValue(
    List<SaleItem> items,
    Map<SaleItem, int> quantities,
  ) {
    return items.fold<double>(
      0,
      (total, item) => total + item.refundUnitPrice * quantities[item]!,
    );
  }

  static double _fixedBundleValue(
    List<SaleItem> items,
    Map<SaleItem, int> quantities,
    int threshold,
    double bundlePrice,
  ) {
    final itemTotals = FixedPriceBundleCalculator.calculateItemTotals(
      quantities: {for (final item in items) item: quantities[item]!},
      priceOf: (item) => item.refundUnitPrice,
      bundleSize: threshold,
      bundlePrice: bundlePrice,
    );
    return itemTotals.values.fold(0, (total, itemTotal) => total + itemTotal);
  }
}
