import 'dart:typed_data'; // <-- IMPORTANTE: Necesario para usar Uint8List

class Product {
  final int? id;
  final String name;
  final int units;
  final double price;
  final double cost;
  final String? imagePath;
  final Uint8List? imageBytes; // <-- NUEVO: Para el binario de la foto
  final int? promotionId;
  final bool isActive;

  Product({
    this.id,
    required this.name,
    required this.units,
    required this.price,
    required this.cost,
    this.imagePath,
    this.imageBytes, // <-- NUEVO
    this.promotionId,
    this.isActive = true,
  });

  Product copyWith({
    int? id,
    String? name,
    int? units,
    double? price,
    double? cost,
    String? imagePath,
    Uint8List? imageBytes, // <-- NUEVO
    int? promotionId,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      units: units ?? this.units,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes, // <-- NUEVO
      promotionId: promotionId ?? this.promotionId,
      isActive: isActive ?? this.isActive,
    );
  }
}
