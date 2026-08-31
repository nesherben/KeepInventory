class Product {
  final int? id;
  final String name;
  final int units;
  final double price;
  final double cost;
  final String? imagePath; // Nueva propiedad

  Product({
    this.id,
    required this.name,
    required this.units,
    required this.price,
    required this.cost,
    this.imagePath,
  });

  Product copyWith({
    int? id,
    String? name,
    int? units,
    double? price,
    double? cost,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      units: units ?? this.units,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
