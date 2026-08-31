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
  Future<List<Sale>> getSales() {
    // TODO: Implementar si decides mostrar un historial de ventas en el futuro
    throw UnimplementedError();
  }

  @override
  Future<double> getTotalCost() {
    // TODO: Implementar consulta compleja para sumar costes (ej: unidades en stock * coste)
    throw UnimplementedError();
  }

  @override
  Future<double> getTotalRevenue() {
    // TODO: Implementar consulta compleja para sumar ingresos (suma de total_amount en sales)
    throw UnimplementedError();
  }
}
