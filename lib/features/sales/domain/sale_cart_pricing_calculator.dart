import '../../inventory/domain/product.dart';
import '../../packs/domain/pack.dart';
import '../../promotions/domain/combo.dart';
import '../../promotions/domain/combo_matcher.dart';
import '../../promotions/domain/fixed_price_bundle_calculator.dart';
import '../../promotions/domain/promotion.dart';
import 'manual_line_discount.dart';

/// Precio completo del carrito: combos detectados + resto con sus promociones.
class CartPricing {
  final ComboMatchResult combos;

  /// Unidades que no forman combo.
  final Map<Product, int> loose;

  /// Total de cada producto (parte de combo + parte suelta), por id.
  final Map<int, double> productTotals;
  final double packTotal;

  /// Importe realmente descontado por descuento manual en cada producto
  /// (por id). Solo incluye los descuentos que se han aplicado.
  final Map<int, double> appliedDiscounts;

  const CartPricing({
    required this.combos,
    required this.loose,
    required this.productTotals,
    required this.packTotal,
    this.appliedDiscounts = const {},
  });

  /// Suma de los descuentos manuales aplicados.
  double get discountTotal =>
      appliedDiscounts.values.fold(0.0, (t, v) => t + v);

  double totalOf(Product product) => productTotals[product.id] ?? 0.0;

  double get total =>
      productTotals.values.fold(0.0, (t, v) => t + v) + packTotal;

  /// Ahorro total por combos.
  double get comboSaving =>
      combos.applications.fold(0.0, (t, a) => t + a.saving);

  /// Unidades de [product] que van dentro de algún combo.
  int comboUnitsOf(Product product) =>
      combos.applications.fold(0, (t, a) => t + (a.usedUnits[product.id] ?? 0));
}

class SaleCartPricingCalculator {
  const SaleCartPricingCalculator._();

  /// Total de un producto según su promoción propia (sin combos).
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

  /// ¿Admite [product] un descuento manual? Si tiene promoción o va dentro de
  /// un combo ([comboUnits] > 0), manda la promoción/combo y no se ofrece.
  static bool canDiscount(
    Product product,
    Map<int, Promotion> promotions, {
    int comboUnits = 0,
  }) {
    if (comboUnits > 0) return false;
    final promotionId = product.promotionId;
    return promotionId == null || promotions[promotionId] == null;
  }

  /// Productos cuyo descuento manual hay que quitar porque pasaron a tener
  /// promoción o a ir dentro de un combo (manda la promoción/combo).
  static List<Product> lineDiscountsToDrop({
    required Map<Product, int> products,
    required Map<Pack, int> packs,
    required Map<int, Promotion> promotions,
    required Set<int> discountedIds,
    List<Combo> combos = const [],
  }) {
    if (discountedIds.isEmpty) return const [];
    final pricing = price(
      products: products,
      packs: packs,
      promotions: promotions,
      combos: combos,
    );
    return [
      for (final product in products.keys)
        if (discountedIds.contains(product.id) &&
            !canDiscount(
              product,
              promotions,
              comboUnits: pricing.comboUnitsOf(product),
            ))
          product,
    ];
  }

  /// Precio del carrito. Los combos ganan: sus unidades van a precio de
  /// combo y solo las sobrantes cuentan para la promoción propia.
  ///
  /// [lineDiscounts] (por id de producto) se aplica al total de la línea
  /// suelta, solo en productos sin promoción ni combo; el resto se ignora.
  static CartPricing price({
    required Map<Product, int> products,
    required Map<Pack, int> packs,
    required Map<int, Promotion> promotions,
    List<Combo> combos = const [],
    Map<int, ManualLineDiscount> lineDiscounts = const {},
  }) {
    final byId = {
      for (final p in products.keys)
        if (p.id != null) p.id!: p,
    };
    final match = combos.isEmpty
        ? ComboMatchResult.empty
        : ComboMatcher.match(
            combos: combos,
            quantities: {
              for (final e in products.entries)
                if (e.key.id != null) e.key.id!: e.value,
            },
            priceOf: (id) => byId[id]?.price ?? 0,
          );

    final comboUnits = <int, int>{};
    final totals = <int, double>{};
    for (final application in match.applications) {
      for (final e in application.usedUnits.entries) {
        comboUnits[e.key] = (comboUnits[e.key] ?? 0) + e.value;
      }
      for (final e in application.lineTotals.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }

    final loose = <Product, int>{
      for (final e in products.entries)
        if (e.value - (comboUnits[e.key.id] ?? 0) > 0)
          e.key: e.value - (comboUnits[e.key.id] ?? 0),
    };
    final applied = <int, double>{};
    for (final product in loose.keys) {
      final id = product.id ?? -1;
      var lineTotal = calculateItemTotal(product, loose, promotions);
      final discount = lineDiscounts[id];
      if (discount != null &&
          canDiscount(product, promotions, comboUnits: comboUnits[id] ?? 0)) {
        final amount = discount.discountOn(lineTotal);
        if (amount > 0) {
          applied[id] = amount;
          lineTotal = roundToCents(lineTotal - amount);
        }
      }
      totals[id] = (totals[id] ?? 0) + lineTotal;
    }

    return CartPricing(
      combos: match,
      loose: loose,
      productTotals: totals,
      appliedDiscounts: applied,
      packTotal: packs.entries.fold<double>(
        0,
        (total, entry) => total + entry.key.price * entry.value,
      ),
    );
  }

  static double calculateCartTotal({
    required Map<Product, int> products,
    required Map<Pack, int> packs,
    required Map<int, Promotion> promotions,
    List<Combo> combos = const [],
  }) => price(
    products: products,
    packs: packs,
    promotions: promotions,
    combos: combos,
  ).total;

  static int countItems({
    required Map<Product, int> products,
    required Map<Pack, int> packs,
  }) {
    final productCount = products.values.fold<int>(0, (sum, qty) => sum + qty);
    final packCount = packs.values.fold<int>(0, (sum, qty) => sum + qty);
    return productCount + packCount;
  }
}
