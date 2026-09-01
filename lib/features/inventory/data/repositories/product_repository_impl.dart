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
      promotionId: product.promotionId,
      isActive: product.isActive,
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
      promotionId: product.promotionId,
      isActive: product.isActive,
    );
    return await datasource.updateProduct(model);
  }

  @override
  Future<int> deleteProduct(int id) async {
    return await datasource.deleteProduct(id);
  }
}
