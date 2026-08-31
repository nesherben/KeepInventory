class Product {
  final int? id;
  final String name;
  final int units;
  final double price;
  final double cost;

  Product({
    this.id,
    required this.name,
    required this.units,
    required this.price,
    required this.cost,
  });

  Product copyWith({
    int? id,
    String? name,
    int? units,
    double? price,
    double? cost,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      units: units ?? this.units,
      price: price ?? this.price,
      cost: cost ?? this.cost,
    );
  }
}
