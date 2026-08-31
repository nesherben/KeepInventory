import '../entities/product.dart';
import '../entities/sale.dart';

abstract class InventoryRepository {
  // --- Operaciones de Productos ---
  Future<List<Product>> getProducts();
  Future<Product?> getProductById(int id);
  Future<int> insertProduct(Product product);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);

  // --- Operaciones de Ventas ---
  /// Registra una nueva venta y resta las unidades del inventario en una misma transacción
  Future<void> processSale(Sale sale);
  Future<List<Sale>> getSales();

  // --- Operaciones del Dashboard ---
  Future<double> getTotalRevenue();
  Future<double> getTotalCost();
}
