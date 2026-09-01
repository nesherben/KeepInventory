import '../../features/inventory/domain/product.dart';
import '../../features/promotions/domain/promotion.dart';
import '../../features/sales/domain/sale.dart';

abstract class InventoryRepository {
  // --- Productos ---
  Future<List<Product>> getProducts();
  Future<int> insertProduct(Product product);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);

  // --- Promociones ---
  Future<List<Promotion>> getPromotions();
  Future<int> insertPromotion(Promotion promotion);
  Future<int> updatePromotion(Promotion promotion);
  Future<int> deletePromotion(int id);

  // --- Ventas, Historial y Ferias ---
  Future<void> processSale(Sale sale);
  Future<List<Sale>> getSales();
  Future<void> refundSale(Sale sale);
  Future<void> updateFairNameForDate(String datePrefix, String? fairName);
  Future<List<String>> getAvailableFairs();
  Future<void> processPartialRefund({
    required Sale originalSale,
    required Map<SaleItem, int> itemsToRefund,
    required Map<SalePackItem, int> packsToRefund,
    required bool restockPacks,
    required double customRefundAmount,
  });

  // --- Dashboard / Métricas ---
  Future<double> getTotalRevenue();
  Future<double> getInventoryCost();
  Future<double> getExpectedRevenue();
  Future<double> getActualNetProfit();
  Future<Map<String, double>> getDailySales();
  Future<Map<String, double>> getDailyNetProfits();
}
