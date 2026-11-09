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
    int? categoryId,
  }) {
    final q = query.trim().toLowerCase();
    final result = products.where((p) {
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) return false;
      if (categoryId != null && p.categoryId != categoryId) return false;
      return switch (filter) {
        InventoryFilter.all => true,
        InventoryFilter.lowStock => StockLevel.of(p.units) == StockLevel.low,
        InventoryFilter.outOfStock => StockLevel.of(p.units) == StockLevel.out,
        InventoryFilter.withPromotion =>
          p.promotionId != null && validPromotionIds.contains(p.promotionId),
      };
    }).toList();

    if (sort != null) {
      // Un único criterio activo; los empates se resuelven siempre por
      // nombre (A→Z) y luego por id, para que el orden sea estable.
      int compare(Product a, Product b) {
        if (sort == InventorySort.margin) {
          // Sin % (precio 0, se muestra "—"): siempre al final
          final pa = a.marginPercent, pb = b.marginPercent;
          if (pa == null && pb != null) return 1;
          if (pb == null && pa != null) return -1;
        }
        final primary = switch (sort) {
          InventorySort.name => compareNames(a.name, b.name),
          InventorySort.units => a.units.compareTo(b.units),
          InventorySort.price => a.price.compareTo(b.price),
          InventorySort.cost => a.cost.compareTo(b.cost),
          // Se ordena por el mismo valor que se muestra en la columna (%)
          InventorySort.margin => (a.marginPercent ?? 0).compareTo(
            b.marginPercent ?? 0,
          ),
        };
        if (primary != 0) return ascending ? primary : -primary;
        final byName = compareNames(a.name, b.name);
        if (byName != 0) return byName;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      }

      result.sort(compare);
    }
    return result;
  }

  /// Comparación "humana" de nombres: sin distinguir mayúsculas ni tildes,
  /// la Ñ va tras la N y los números se comparan por valor
  /// ("Pendiente 2" < "Pendiente 10").
  static int compareNames(String a, String b) {
    final x = _foldName(a), y = _foldName(b);
    var i = 0, j = 0;
    while (i < x.length && j < y.length) {
      final cx = x.codeUnitAt(i), cy = y.codeUnitAt(j);
      if (_isDigit(cx) && _isDigit(cy)) {
        var ei = i, ej = j;
        while (ei < x.length && _isDigit(x.codeUnitAt(ei))) {
          ei++;
        }
        while (ej < y.length && _isDigit(y.codeUnitAt(ej))) {
          ej++;
        }
        final nx = x.substring(i, ei).replaceFirst(RegExp(r'^0+(?=\d)'), '');
        final ny = y.substring(j, ej).replaceFirst(RegExp(r'^0+(?=\d)'), '');
        final byValue = nx.length != ny.length
            ? nx.length.compareTo(ny.length)
            : nx.compareTo(ny);
        if (byValue != 0) return byValue;
        i = ei;
        j = ej;
        continue;
      }
      if (cx != cy) return cx.compareTo(cy);
      i++;
      j++;
    }
    return (x.length - i).compareTo(y.length - j);
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  static const _accents = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ç': 'c',
    // "~" va después de cualquier letra: la ñ queda entre la n y la o
    'ñ': 'n~',
  };

  static String _foldName(String name) {
    final buffer = StringBuffer();
    for (final ch in name.trim().toLowerCase().split('')) {
      buffer.write(_accents[ch] ?? ch);
    }
    return buffer.toString();
  }
}
