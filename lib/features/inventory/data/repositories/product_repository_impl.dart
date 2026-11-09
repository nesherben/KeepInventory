import 'dart:typed_data';

import '../../data/datasources/product_local_datasource.dart';
import '../../data/product_model.dart';
import '../../domain/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDatasource datasource;

  ProductRepositoryImpl(this.datasource);

  @override
  Future<List<Product>> getProducts() async {
    return await datasource.getProducts();
  }

  @override
  Future<Product?> getProductById(int id) async {
    return await datasource.getProductById(id);
  }

  @override
  Future<int> insertProduct(Product product) async {
    final model = ProductModel(
      name: product.name,
      units: product.units,
      price: product.price,
      cost: product.cost,
      imagePath: product.imagePath,
      imageBytes: product.imageBytes, // 💡 ¡FALTABA ESTO AQUÍ!
      promotionId: product.promotionId,
      isActive: product.isActive,
      categoryId: product.categoryId,
    );
    return await datasource.insertProduct(model);
  }

  @override
  Future<int> updateProduct(Product product) async {
    final model = ProductModel(
      id: product.id,
      name: product.name,
      units: product.units,
      price: product.price,
      cost: product.cost,
      imagePath: product.imagePath,
      imageBytes: product.imageBytes, // 💡 ¡Y AQUÍ TAMBIÉN!
      promotionId: product.promotionId,
      isActive: product.isActive,
      categoryId: product.categoryId,
    );
    return await datasource.updateProduct(model);
  }

  @override
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
  }) async {
    await datasource.updateFields(id, {
      'name': ?name,
      'units': ?units,
      'price': ?price,
      'cost': ?cost,
      if (promotionId != null || clearPromotion) 'promotion_id': promotionId,
      if (categoryId != null || clearCategory) 'category_id': categoryId,
      // Foto nueva: se guarda en la BD y se olvida la ruta antigua
      if (imageBytes != null) ...{
        'image_bytes': imageBytes,
        'image_path': null,
      },
    });
  }

  @override
  Future<void> addUnits(int id, int delta) => datasource.addUnits(id, delta);

  @override
  Future<int> setPromotionForCategory(int categoryId, int promotionId) =>
      datasource.setPromotionForCategory(categoryId, promotionId);

  @override
  Future<int> deleteProduct(int id) async {
    return await datasource.deleteProduct(id);
  }
}
