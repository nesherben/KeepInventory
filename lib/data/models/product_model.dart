import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    super.id,
    required super.name,
    required super.units,
    required super.price,
    required super.cost,
    super.imagePath,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      units: map['units'] as int,
      price: map['price'] as double,
      cost: map['cost'] as double,
      imagePath: map['image_path'] as String?, // Leemos de la BD
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'units': units,
      'price': price,
      'cost': cost,
      'image_path': imagePath, // Escribimos en la BD
    };
  }
}
