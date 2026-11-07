import 'product.dart';

/// Nivel de stock de un producto o pack, para avisos visuales.
enum StockLevel {
  ok,
  low,
  out;

  /// Con estas unidades o menos se considera "stock bajo".
  static const int lowThreshold = 3;

  static StockLevel of(int units) {
    if (units <= 0) return StockLevel.out;
    if (units <= lowThreshold) return StockLevel.low;
    return StockLevel.ok;
  }
}

/// Margen por unidad (precio − coste) y en % sobre el precio de venta.
extension ProductMargin on Product {
  double get marginAmount => price - cost;

  /// Nulo si el precio es 0 (no tiene sentido un %).
  double? get marginPercent => price > 0 ? (price - cost) / price * 100 : null;
}

/// Filtros rápidos del inventario.
enum InventoryFilter { all, lowStock, outOfStock, withPromotion }

/// Criterios de orden de la tabla.
enum InventorySort { name, units, price, cost, margin }

/// Resumen que se muestra encima de la lista.
class InventorySummary {
  const InventorySummary({
    required this.products,
    required this.units,
    required this.lowStock,
    required this.outOfStock,
  });

  final int products;
  final int units;
  final int lowStock;
  final int outOfStock;

  factory InventorySummary.of(Iterable<Product> products) {
    var units = 0, low = 0, out = 0, count = 0;
    for (final p in products) {
      count++;
      units += p.units > 0 ? p.units : 0;
      switch (StockLevel.of(p.units)) {
        case StockLevel.low:
          low++;
        case StockLevel.out:
          out++;
        case StockLevel.ok:
          break;
      }
    }
    return InventorySummary(
      products: count,
      units: units,
      lowStock: low,
      outOfStock: out,
    );
  }
}

/// Aplica búsqueda, filtro y orden. Lógica pura (sin Flutter) para testearla.
abstract final class InventoryView {
  static List<Product> apply(
    Iterable<Product> products, {
    String query = '',
    InventoryFilter filter = InventoryFilter.all,
    Set<int> validPromotionIds = const {},
    InventorySort? sort,
    bool ascending = true,
  }) {
    final q = query.trim().toLowerCase();
    final result = products.where((p) {
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) return false;
      return switch (filter) {
        InventoryFilter.all => true,
        InventoryFilter.lowStock => StockLevel.of(p.units) == StockLevel.low,
        InventoryFilter.outOfStock => StockLevel.of(p.units) == StockLevel.out,
        InventoryFilter.withPromotion =>
          p.promotionId != null && validPromotionIds.contains(p.promotionId),
      };
    }).toList();

    if (sort != null) {
      int compare(Product a, Product b) => switch (sort) {
        InventorySort.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        InventorySort.units => a.units.compareTo(b.units),
        InventorySort.price => a.price.compareTo(b.price),
        InventorySort.cost => a.cost.compareTo(b.cost),
        InventorySort.margin => a.marginAmount.compareTo(b.marginAmount),
      };
      result.sort((a, b) => ascending ? compare(a, b) : compare(b, a));
    }
    return result;
  }
}
