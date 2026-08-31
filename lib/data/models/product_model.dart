import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    super.id,
    required super.name,
    required super.units,
    required super.price,
    required super.cost,
    super.imagePath,
    super.promotionId,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      units: map['units'] as int,
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
      promotionId: map['promotion_id'] as int?, // <--- Aquí lee de SQLite
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'units': units,
      'price': price,
      'cost': cost,
      'image_path': imagePath,
      'promotion_id': promotionId, // <--- Aquí escribe en SQLite
    };
  }
}
