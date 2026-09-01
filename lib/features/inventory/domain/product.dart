class Product {
  final int? id;
  final String name;
  final int units;
  final double price;
  final double cost;
  final String? imagePath;
  final int? promotionId;
  final bool isActive; // NUEVO: Para el borrado lógico

  Product({
    this.id,
    required this.name,
    required this.units,
    required this.price,
    required this.cost,
    this.imagePath,
    this.promotionId,
    this.isActive = true, // Por defecto siempre está activo
  });

  Product copyWith({
    int? id,
    String? name,
    int? units,
    double? price,
    double? cost,
    String? imagePath,
    int? promotionId,
    bool? isActive, // NUEVO
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      units: units ?? this.units,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      imagePath: imagePath ?? this.imagePath,
      promotionId: promotionId ?? this.promotionId,
      isActive: isActive ?? this.isActive, // NUEVO
    );
  }
}
