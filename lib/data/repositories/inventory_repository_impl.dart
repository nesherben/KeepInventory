import 'package:keepinventory/data/models/promotion_model.dart';
import 'package:keepinventory/domain/entities/promotion.dart';

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
      promotionId: product.promotionId, // <--- Añadir esto
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
      promotionId: product.promotionId, // <--- Y esto
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

  // --- Implementación de Promociones (NUEVO) ---
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
}
