import 'sale.dart';
import '../../promotions/domain/combo_matcher.dart';
import '../../promotions/domain/fixed_price_bundle_calculator.dart';

/// Unidades de una línea suelta que pasan a formar parte de un combo
/// al recalcular una devolución.
class ComboAbsorption {
  final SaleItem line;
  final int saleComboId;
  final int units;
  final double value;

  const ComboAbsorption({
    required this.line,
    required this.saleComboId,
    required this.units,
    required this.value,
  });
}

/// Valor de lo que se queda el cliente tras una devolución.
class KeptSaleValue {
  /// Valor de cada línea conservada.
  final Map<SaleItem, double> lineValues;

  /// Veces que sigue aplicándose cada combo de la venta (por id).
  final Map<int, int> comboCounts;

  /// Unidades sueltas absorbidas por combos (no incluidas en [lineValues]).
  final List<ComboAbsorption> absorptions;
  final double packValue;

  const KeptSaleValue({
    required this.lineValues,
    required this.comboCounts,
    required this.packValue,
    this.absorptions = const [],
  });

  double get total =>
      lineValues.values.fold(0.0, (t, v) => t + v) +
      absorptions.fold(0.0, (t, a) => t + a.value) +
      packValue;
}

class SaleRefundCalculator {
  const SaleRefundCalculator._();

  /// Importe a reembolsar = lo cobrado − lo que vale lo que se queda.
  /// Los grupos (promoción o combo) intactos valen lo que se cobró; los
  /// afectados se recalculan.
  static double calculateRefundAmount({
    required Map<SaleItem, int> originalItemQuantities,
    required Map<SaleItem, int> keptItemQuantities,
    required Map<SalePackItem, int> originalPackQuantities,
    required Map<SalePackItem, int> keptPackQuantities,
    List<SaleCombo> combos = const [],
  }) {
    final paid =
        originalItemQuantities.entries.fold<double>(
          0,
          (t, e) => t + e.key.historicalPrice * e.value,
        ) +
        originalPackQuantities.entries.fold<double>(
          0,
          (t, e) => t + e.key.historicalPrice * e.value,
        );
    final kept = calculateKeptValue(
      originalItemQuantities: originalItemQuantities,
      keptItemQuantities: keptItemQuantities,
      keptPackQuantities: keptPackQuantities,
      combos: combos,
    );
    final refund = paid - kept.total;
    return refund < 0 ? 0 : refund;
  }

  /// Valor restante del carrito.
  static double calculateRemainingCartValue({
    required Map<SaleItem, int> originalItemQuantities,
    required Map<SaleItem, int> keptItemQuantities,
    required Map<SalePackItem, int> keptPackQuantities,
    List<SaleCombo> combos = const [],
  }) => calculateKeptValue(
    originalItemQuantities: originalItemQuantities,
    keptItemQuantities: keptItemQuantities,
    keptPackQuantities: keptPackQuantities,
    combos: combos,
  ).total;

  static KeptSaleValue calculateKeptValue({
    required Map<SaleItem, int> originalItemQuantities,
    required Map<SaleItem, int> keptItemQuantities,
    required Map<SalePackItem, int> keptPackQuantities,
    List<SaleCombo> combos = const [],
  }) {
    int kept(SaleItem i) => keptItemQuantities[i] ?? 0;
    int original(SaleItem i) => originalItemQuantities[i] ?? 0;

    final values = <SaleItem, double>{};
    void add(SaleItem item, double value) =>
        values[item] = (values[item] ?? 0) + value;

    final combosById = {
      for (final c in combos)
        if (c.id != null) c.id!: c,
    };
    final comboCounts = <int, int>{};

    // Unidades sueltas: líneas normales + las que sobran de combos rotos
    final loose = <SaleItem, int>{};
    final leftovers = <SaleItem, int>{};

    final comboLines = <int, List<SaleItem>>{};
    for (final item in originalItemQuantities.keys) {
      final comboId = item.saleComboId;
      if (comboId != null && combosById.containsKey(comboId)) {
        comboLines.putIfAbsent(comboId, () => []).add(item);
      } else {
        loose[item] = kept(item);
      }
    }

    // 1. Combos: intactos valen lo cobrado; rotos se vuelven a emparejar.
    // Las unidades sueltas de la misma venta también pueden rehacer el
    // combo (así da igual qué línea de "Teclado" se marque al devolver).
    final absorbed = <SaleItem>{};
    final absorptions = <ComboAbsorption>[];
    for (final entry in comboLines.entries) {
      final saleCombo = combosById[entry.key]!;
      final lines = entry.value;
      final affected = lines.any((i) => kept(i) < original(i));
      if (!affected) {
        for (final line in lines) {
          add(line, line.historicalPrice * kept(line));
        }
        comboCounts[entry.key] = saleCombo.quantity;
        continue;
      }

      final comboProducts = saleCombo.asCombo.productIds;
      // Primero las líneas del combo, después las sueltas del mismo producto
      final candidates = [
        ...lines,
        ...loose.keys.where(
          (i) => comboProducts.contains(i.productId) && loose[i]! > 0,
        ),
      ];
      int available(SaleItem i) => lines.contains(i) ? kept(i) : loose[i]!;

      final lineByProduct = <int, SaleItem>{};
      final quantities = <int, int>{};
      for (final line in candidates) {
        lineByProduct.putIfAbsent(line.productId, () => line);
        quantities[line.productId] =
            (quantities[line.productId] ?? 0) + available(line);
      }
      final match = ComboMatcher.match(
        combos: [saleCombo.asCombo],
        quantities: quantities,
        priceOf: (id) => lineByProduct[id]!.refundUnitPrice,
      );
      final application = match.applications.isEmpty
          ? null
          : match.applications.first;
      comboCounts[entry.key] = application?.count ?? 0;

      // Reparte las unidades del combo entre las líneas candidatas
      final comboUnitsLeft = {...?application?.usedUnits};
      final comboValueLeft = {...?application?.lineTotals};
      for (final line in candidates) {
        final units = available(line);
        if (units == 0) continue;
        final productUnits = comboUnitsLeft[line.productId] ?? 0;
        final inCombo = productUnits < units ? productUnits : units;
        if (inCombo > 0) {
          final value =
              comboValueLeft[line.productId]! * inCombo / productUnits;
          if (lines.contains(line)) {
            add(line, value);
          } else {
            absorptions.add(
              ComboAbsorption(
                line: line,
                saleComboId: entry.key,
                units: inCombo,
                value: value,
              ),
            );
          }
          comboUnitsLeft[line.productId] = productUnits - inCombo;
          comboValueLeft[line.productId] =
              comboValueLeft[line.productId]! - value;
        }
        if (lines.contains(line)) {
          if (units - inCombo > 0) leftovers[line] = units - inCombo;
        } else if (inCombo > 0) {
          loose[line] = units - inCombo;
          absorbed.add(line);
        }
      }
    }

    // 2. Sueltas por grupo de promoción
    final groups = <int?, List<SaleItem>>{};
    for (final item in {...loose.keys, ...leftovers.keys}) {
      groups.putIfAbsent(item.promotionId, () => []).add(item);
    }
    for (final group in groups.entries) {
      final items = group.value;
      final affected = items.any(
        (i) =>
            leftovers.containsKey(i) ||
            absorbed.contains(i) ||
            kept(i) < original(i),
      );
      int units(SaleItem i) => leftovers[i] ?? loose[i] ?? 0;

      if (!affected) {
        for (final item in items) {
          add(item, item.historicalPrice * units(item));
        }
        continue;
      }

      if (group.key == null) {
        // Sin promoción: lo cobrado; las sobrantes de combo, a precio normal
        for (final item in items) {
          final price = leftovers.containsKey(item)
              ? item.refundUnitPrice
              : item.historicalPrice;
          add(item, price * units(item));
        }
        continue;
      }

      final quantities = {
        for (final i in items)
          if (units(i) > 0) i: units(i),
      };
      if (quantities.isEmpty) continue;
      final groupValue = calculateGroupValue(
        keptItems: quantities.keys.toList(),
        keptQuantities: quantities,
      );
      // Reparto proporcional al precio completo de cada línea
      final fullValue = quantities.entries.fold<double>(
        0,
        (t, e) => t + e.key.refundUnitPrice * e.value,
      );
      final unitCount = quantities.values.fold<int>(0, (t, v) => t + v);
      for (final e in quantities.entries) {
        final share = fullValue > 0
            ? e.key.refundUnitPrice * e.value / fullValue
            : e.value / unitCount;
        add(e.key, groupValue * share);
      }
    }

    return KeptSaleValue(
      lineValues: values,
      comboCounts: comboCounts,
      absorptions: absorptions,
      packValue: keptPackQuantities.entries.fold<double>(
        0,
        (t, e) => t + e.key.historicalPrice * e.value,
      ),
    );
  }

  /// Líneas y combos de la venta tras devolver [itemsToRefund], con los
  /// precios recalculados (la suma de líneas = lo que vale lo que queda).
  /// Las unidades sueltas que rehacen un combo pasan a una línea del combo,
  /// así ninguna línea mezcla precio de combo y precio normal; los combos que
  /// se quedan a 0 desaparecen y sus líneas pasan a ser sueltas.
  static ({List<SaleItem> items, List<SaleCombo> combos}) remainingAfterRefund({
    required Sale sale,
    required Map<SaleItem, int> itemsToRefund,
  }) {
    final keptQuantities = {
      for (final i in sale.items) i: i.quantity - (itemsToRefund[i] ?? 0),
    };
    final kept = calculateKeptValue(
      originalItemQuantities: {for (final i in sale.items) i: i.quantity},
      keptItemQuantities: keptQuantities,
      keptPackQuantities: const {},
      combos: sale.combos,
    );
    final liveCombos = {
      for (final c in sale.combos)
        if (c.id != null && (kept.comboCounts[c.id] ?? c.quantity) > 0)
          c.id!: kept.comboCounts[c.id] ?? c.quantity,
    };

    final absorbedUnits = <SaleItem, int>{};
    for (final a in kept.absorptions) {
      absorbedUnits[a.line] = (absorbedUnits[a.line] ?? 0) + a.units;
    }

    final drafts = <_LineDraft>[];
    for (final item in sale.items) {
      final units = keptQuantities[item]! - (absorbedUnits[item] ?? 0);
      if (units <= 0) continue;
      final comboId = liveCombos.containsKey(item.saleComboId)
          ? item.saleComboId
          : null;
      drafts.add(_LineDraft(item, comboId, units, kept.lineValues[item] ?? 0));
    }
    for (final a in kept.absorptions) {
      final target = drafts
          .where(
            (d) =>
                d.comboId == a.saleComboId &&
                d.from.productId == a.line.productId,
          )
          .firstOrNull;
      if (target != null) {
        target.units += a.units;
        target.value += a.value;
      } else {
        drafts.add(_LineDraft(a.line, a.saleComboId, a.units, a.value));
      }
    }

    return (
      items: [
        for (final d in drafts)
          SaleItem(
            saleId: sale.id,
            productId: d.from.productId,
            productName: d.from.productName,
            quantity: d.units,
            historicalPrice: d.value / d.units,
            originalPrice: d.from.originalPrice,
            promotionId: d.from.promotionId,
            promoType: d.from.promoType,
            promoThreshold: d.from.promoThreshold,
            promoDiscount: d.from.promoDiscount,
            saleComboId: d.comboId,
          ),
      ],
      combos: [
        for (final c in sale.combos)
          if (liveCombos.containsKey(c.id))
            SaleCombo(
              id: c.id,
              comboId: c.comboId,
              name: c.name,
              price: c.price,
              quantity: liveCombos[c.id]!,
              slots: c.slots,
            ),
      ],
    );
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

class _LineDraft {
  _LineDraft(this.from, this.comboId, this.units, this.value);

  final SaleItem from;
  final int? comboId;
  int units;
  double value;
}
