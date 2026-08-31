import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/local_database_datasource.dart';
import '../models/product_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final LocalDatabaseDatasource datasource;

  InventoryRepositoryImpl(this.datasource);

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
    );
    return await datasource.updateProduct(model);
  }

  @override
  Future<int> deleteProduct(int id) async {
    return await datasource.deleteProduct(id);
  }

  @override
  Future<void> processSale(Sale sale) async {
    await datasource.processSale(sale);
  }

  @override
  Future<double> getTotalRevenue() async {
    return await datasource.getTotalRevenue();
  }

  @override
  Future<double> getInventoryCost() async {
    return await datasource.getInventoryCost();
  }

  @override
  Future<double> getExpectedRevenue() async {
    return await datasource.getExpectedRevenue();
  }

  @override
  Future<Map<String, double>> getDailySales() async {
    return await datasource.getDailySales();
  }

  // NUEVO
  @override
  Future<List<Sale>> getSales() async {
    return await datasource.getSales();
  }
}
