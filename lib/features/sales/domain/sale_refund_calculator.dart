import 'sale.dart';
import '../../promotions/domain/fixed_price_bundle_calculator.dart';

class SaleRefundCalculator {
  const SaleRefundCalculator._();

  /// Importe a reembolsar. Solo los grupos de promoción afectados se
  /// recalculan; el resto (sin promo o intactos) usa el precio cobrado
  /// (`historicalPrice`) de las unidades devueltas.
  static double calculateRefundAmount({
    required Map<SaleItem, int> originalItemQuantities,
    required Map<SaleItem, int> keptItemQuantities,
    required Map<SalePackItem, int> originalPackQuantities,
    required Map<SalePackItem, int> keptPackQuantities,
  }) {
    var refund = 0.0;

    for (final entry in originalPackQuantities.entries) {
      final returned = entry.value - (keptPackQuantities[entry.key] ?? 0);
      refund += entry.key.historicalPrice * returned;
    }

    final groups = _groupByPromotion(originalItemQuantities);
    for (final group in groups.entries) {
      final items = group.value;

      final isAffected = items.any(
        (i) => (keptItemQuantities[i] ?? 0) < (originalItemQuantities[i] ?? 0),
      );
      if (!isAffected) continue;

      // Sin promoción: solo se devuelve lo cobrado de las unidades devueltas.
      if (group.key == null) {
        for (final item in items) {
          final returned =
              originalItemQuantities[item]! - (keptItemQuantities[item] ?? 0);
          refund += item.historicalPrice * returned;
        }
        continue;
      }

      // Con promoción afectada: lo cobrado antes - lo que valen las que quedan.
      final paidBefore = items.fold<double>(
        0,
        (t, i) => t + i.historicalPrice * originalItemQuantities[i]!,
      );
      final keptItems = items
          .where((i) => (keptItemQuantities[i] ?? 0) > 0)
          .toList();
      final newValue = keptItems.isEmpty
          ? 0.0
          : calculateGroupValue(
              keptItems: keptItems,
              keptQuantities: keptItemQuantities,
            );
      refund += paidBefore - newValue;
    }

    return refund < 0 ? 0 : refund;
  }

  /// Valor restante del carrito (se mantiene por compatibilidad).
  static double calculateRemainingCartValue({
    required Map<SaleItem, int> originalItemQuantities,
    required Map<SaleItem, int> keptItemQuantities,
    required Map<SalePackItem, int> keptPackQuantities,
  }) {
    var totalValue = 0.0;

    for (final entry in keptPackQuantities.entries) {
      totalValue += entry.key.historicalPrice * entry.value;
    }

    final groups = _groupByPromotion(originalItemQuantities);
    for (final group in groups.entries) {
      final items = group.value;
      final keptItems = items
          .where((i) => (keptItemQuantities[i] ?? 0) > 0)
          .toList();
      if (keptItems.isEmpty) continue;

      final isAffected = items.any(
        (i) => (keptItemQuantities[i] ?? 0) < (originalItemQuantities[i] ?? 0),
      );
      if (group.key == null || !isAffected) {
        totalValue += _paidValue(keptItems, keptItemQuantities);
        continue;
      }

      totalValue += calculateGroupValue(
        keptItems: keptItems,
        keptQuantities: keptItemQuantities,
      );
    }

    return totalValue;
  }

  /// Valor total de un grupo de promoción con las unidades que se conservan.
  static double calculateGroupValue({
    required List<SaleItem> keptItems,
    required Map<SaleItem, int> keptQuantities,
  }) {
    final promotion = keptItems.first;
    final type = promotion.promoType;
    final threshold = promotion.promoThreshold;
    final discount = promotion.promoDiscount;
    if (type == null || threshold == null || discount == null) {
      return _fullPriceValue(keptItems, keptQuantities);
    }

    final quantity = keptItems.fold<int>(0, (t, i) => t + keptQuantities[i]!);
    if (quantity < threshold) return _fullPriceValue(keptItems, keptQuantities);

    if (type == 'percentage') {
      return keptItems.fold<double>(
        0,
        (t, i) =>
            t + i.refundUnitPrice * (1 - discount / 100) * keptQuantities[i]!,
      );
    }
    if (type == 'bundle_fixed_price') {
      return _fixedBundleValue(keptItems, keptQuantities, threshold, discount);
    }
    return _paidValue(keptItems, keptQuantities);
  }

  static Map<int?, List<SaleItem>> _groupByPromotion(
    Map<SaleItem, int> originalQuantities,
  ) {
    final groups = <int?, List<SaleItem>>{};
    for (final entry in originalQuantities.entries) {
      if (entry.value > 0) {
        groups.putIfAbsent(entry.key.promotionId, () => []).add(entry.key);
      }
    }
    return groups;
  }

  static double _paidValue(List<SaleItem> items, Map<SaleItem, int> kept) {
    return items.fold<double>(0, (t, i) => t + i.historicalPrice * kept[i]!);
  }

  static double _fullPriceValue(
    List<SaleItem> items,
    Map<SaleItem, int> quantities,
  ) {
    return items.fold<double>(
      0,
      (t, i) => t + i.refundUnitPrice * quantities[i]!,
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
    return itemTotals.values.fold(0, (t, v) => t + v);
  }
}
