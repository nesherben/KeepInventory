import 'dart:typed_data';

import '../bulk_product_edit.dart';
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
    int? categoryId,
    bool clearCategory = false,
  });

  /// Pone la promoción a todos los productos de una categoría (cada uno se
  /// puede cambiar después por separado). Devuelve cuántos se cambiaron.
  Future<int> setPromotionForCategory(int categoryId, int promotionId);

  /// Aplica [edit] a [products] de una vez (todo o nada). Devuelve cuántos
  /// productos se cambiaron.
  Future<int> updateMany(BulkProductEdit edit, List<Product> products);

  /// Borra (de forma lógica) varios productos de una vez. Devuelve cuántos.
  Future<int> deleteMany(List<int> ids);

  /// Suma (o resta) unidades de stock de forma atómica.
  Future<void> addUnits(int id, int delta);
}
