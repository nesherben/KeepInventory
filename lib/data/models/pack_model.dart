class PackItemModel {
  final int? id;
  final int packId;
  final int productId;
  final String productName;
  final int quantity;

  PackItemModel({
    this.id,
    required this.packId,
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {'pack_id': packId, 'product_id': productId, 'quantity': quantity};
  }

  factory PackItemModel.fromMap(Map<String, dynamic> map) {
    return PackItemModel(
      id: map['id'],
      packId: map['pack_id'],
      productId: map['product_id'],
      productName: map['product_name'] ?? 'Producto desconocido',
      quantity: map['quantity'],
    );
  }
}

class PackModel {
  final int? id;
  final String name;
  final double price;
  final String? imagePath;
  final List<PackItemModel> items;

  PackModel({
    this.id,
    required this.name,
    required this.price,
    this.imagePath,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'image_path': imagePath};
  }

  factory PackModel.fromMap(
    Map<String, dynamic> map,
    List<PackItemModel> items,
  ) {
    return PackModel(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      imagePath: map['image_path'],
      items: items,
    );
  }
}
