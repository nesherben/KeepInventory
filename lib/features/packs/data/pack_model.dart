import 'dart:typed_data'; // <-- IMPORTANTE: Necesario para usar Uint8List

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
  final int units; // 💡 ¡AÑADIDO! Stock de unidades montadas del pack
  final String? imagePath;
  final Uint8List? imageBytes; // Variable para el binario
  final List<PackItemModel> items;

  PackModel({
    this.id,
    required this.name,
    required this.price,
    this.units = 1, // 💡 Valor por defecto
    this.imagePath,
    this.imageBytes,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'units': units, // 💡 ¡AÑADIDO al mapa de SQLite!
      'image_path': imagePath,
      'image_bytes': imageBytes, // Guarda el BLOB en SQLite
    };
  }

  factory PackModel.fromMap(
    Map<String, dynamic> map,
    List<PackItemModel> items,
  ) {
    return PackModel(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      units: map['units'] as int? ?? 1, // 💡 ¡AÑADIDO al leer de SQLite!
      imagePath: map['image_path'],
      imageBytes: map['image_bytes'] as Uint8List?, // Lee el BLOB de SQLite
      items: items,
    );
  }
}
