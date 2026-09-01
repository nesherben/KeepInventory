import '../../data/datasources/promotion_local_datasource.dart';
import '../../data/promotion_model.dart';
import '../../domain/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  final PromotionLocalDatasource datasource;

  PromotionRepositoryImpl(this.datasource);

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
