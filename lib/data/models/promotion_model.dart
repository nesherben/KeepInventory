import '../../domain/entities/promotion.dart';

class PromotionModel extends Promotion {
  PromotionModel({
    super.id,
    required super.name,
    required super.type,
    required super.threshold,
    required super.discountValue,
  });

  factory PromotionModel.fromMap(Map<String, dynamic> map) {
    return PromotionModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      threshold: map['threshold'] as int,
      discountValue: (map['discount_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'threshold': threshold,
      'discount_value': discountValue,
    };
  }
}
