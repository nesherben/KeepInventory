import '../../domain/repositories/inventory_repository.dart';
import '../../features/inventory/data/product_model.dart';
import '../../features/inventory/domain/product.dart';
import '../../features/promotions/data/promotion_model.dart';
import '../../features/promotions/domain/promotion.dart';
import '../../features/sales/domain/sale.dart';
import '../datasources/local_database_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final LocalDatabaseDatasource datasource;

  InventoryRepositoryImpl(this.datasource);

  // --- Productos ---
  @override
  Future<List<Product>> getProducts() async {
    return await datasource.getProducts();
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

  // --- Promociones ---
  @override
  Future<List<Promotion>> getPromotions() async {
    return await datasource.getPromotions();
  }

  @override
  Future<int> insertPromotion(Promotion promotion) async {
    final model = PromotionModel(
      name: promotion.name,
      type: promotion.type,
      threshold: promotion.threshold,
      discountValue: promotion.discountValue,
    );
    return await datasource.insertPromotion(model);
  }

  @override
  Future<int> updatePromotion(Promotion promotion) async {
    final model = PromotionModel(
      id: promotion.id,
      name: promotion.name,
      type: promotion.type,
      threshold: promotion.threshold,
      discountValue: promotion.discountValue,
    );
    return await datasource.updatePromotion(model);
  }

  @override
  Future<int> deletePromotion(int id) async {
    return await datasource.deletePromotion(id);
  }

  // --- Ventas, Historial y Ferias ---
  @override
  Future<void> processSale(Sale sale) async {
    await datasource.processSale(sale);
  }

  @override
  Future<List<Sale>> getSales() async {
    return await datasource.getSales();
  }

  @override
  Future<void> refundSale(Sale sale) async {
    await datasource.refundSale(sale);
  }

  // NUEVO: Puente para la devolución parcial
  @override
  Future<void> processPartialRefund({
    required Sale originalSale,
    required Map<SaleItem, int> itemsToRefund,
    required Map<SalePackItem, int> packsToRefund,
    required bool restockPacks,
    required double customRefundAmount,
  }) async {
    await datasource.processPartialRefund(
      originalSale: originalSale,
      itemsToRefund: itemsToRefund,
      packsToRefund: packsToRefund,
      restockPacks: restockPacks,
      customRefundAmount: customRefundAmount,
    );
  }

  @override
  Future<void> updateFairNameForDate(
    String datePrefix,
    String? fairName,
  ) async {
    await datasource.updateFairNameForDate(datePrefix, fairName);
  }

  @override
  Future<List<String>> getAvailableFairs() async {
    return await datasource.getAvailableFairs();
  }

  // --- Dashboard / Métricas ---
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
  Future<double> getActualNetProfit() async {
    return await datasource.getActualNetProfit();
  }

  @override
  Future<Map<String, double>> getDailySales() async {
    return await datasource.getDailySales();
  }

  @override
  Future<Map<String, double>> getDailyNetProfits() async {
    return await datasource.getDailyNetProfits();
  }
}
