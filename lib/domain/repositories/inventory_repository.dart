import 'package:keepinventory/domain/entities/promotion.dart';

import '../entities/product.dart';
import '../entities/sale.dart';

abstract class InventoryRepository {
  Future<List<Product>> getProducts();
  Future<Product?> getProductById(int id);
  Future<int> insertProduct(Product product);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);

  Future<void> processSale(Sale sale);
  Future<List<Sale>> getSales();

  // Métricas para el Dashboard
  Future<double> getTotalRevenue();
  Future<double> getInventoryCost();
  Future<double> getExpectedRevenue();

  // NUEVO: Métodos de Promociones
  Future<List<Promotion>> getPromotions();
  Future<int> insertPromotion(Promotion promotion);
  Future<int> updatePromotion(Promotion promotion);
  Future<int> deletePromotion(int id);
}
