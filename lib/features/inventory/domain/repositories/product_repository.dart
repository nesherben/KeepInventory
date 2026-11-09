import 'dart:typed_data';

import '../product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product?> getProductById(int id);
  Future<int> insertProduct(Product product);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);

  /// Cambia solo los campos indicados del producto.
  Future<void> updateFields(
    int id, {
    String? name,
    int? units,
    double? price,
    double? cost,
    int? promotionId,
    bool clearPromotion = false,
    Uint8List? imageBytes,
  });

  /// Suma (o resta) unidades de stock de forma atómica.
  Future<void> addUnits(int id, int delta);
}
