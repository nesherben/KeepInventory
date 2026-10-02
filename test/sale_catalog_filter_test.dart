import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';
import 'package:keepinventory/features/packs/domain/pack.dart';
import 'package:keepinventory/features/sales/domain/sale_catalog_filter.dart';

void main() {
  test('filters products case-insensitively by product name', () {
    final products = [_product(1, 'Red mug'), _product(2, 'Brush')];

    expect(SaleCatalogFilter.filterProducts(products, 'MUG').map((p) => p.id), [
      1,
    ]);
  });

  test('filters packs by pack name or component name', () {
    final packs = [
      _pack(1, 'Gift box', 'Red mug'),
      _pack(2, 'Travel kit', 'Brush'),
    ];

    expect(SaleCatalogFilter.filterPacks(packs, 'MUG').map((pack) => pack.id), [
      1,
    ]);
    expect(
      SaleCatalogFilter.filterPacks(packs, 'gift').map((pack) => pack.id),
      [1],
    );
  });
}

Product _product(int id, String name) {
  return Product(id: id, name: name, units: 1, price: 1, cost: 1);
}

Pack _pack(int id, String name, String componentName) {
  return Pack(
    id: id,
    name: name,
    price: 1,
    items: [PackItem(productId: id, productName: componentName, quantity: 1)],
  );
}
