import '../../inventory/domain/product.dart';
import '../../packs/domain/pack.dart';

class SaleCatalogFilter {
  const SaleCatalogFilter._();

  /// Por nombre y, si se indica, por categoría.
  static List<Product> filterProducts(
    Iterable<Product> products,
    String query, {
    int? categoryId,
  }) {
    final normalizedQuery = query.toLowerCase();
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(normalizedQuery) &&
              (categoryId == null || product.categoryId == categoryId),
        )
        .toList();
  }

  static List<Pack> filterPacks(Iterable<Pack> packs, String query) {
    final normalizedQuery = query.toLowerCase();
    return packs.where((pack) {
      final matchesPackName = pack.name.toLowerCase().contains(normalizedQuery);
      final matchesProductName = pack.items.any(
        (item) =>
            (item.productName ?? '').toLowerCase().contains(normalizedQuery),
      );
      return matchesPackName || matchesProductName;
    }).toList();
  }
}
