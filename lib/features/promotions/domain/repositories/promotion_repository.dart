import '../promotion.dart';

abstract class PromotionRepository {
  Future<List<Promotion>> getPromotions();
  Future<int> insertPromotion(Promotion promotion);
  Future<int> updatePromotion(Promotion promotion);
  Future<int> deletePromotion(int id);
}
