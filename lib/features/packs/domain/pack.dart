import 'dart:typed_data'; // <-- IMPORTANTE: Necesario para usar Uint8List

class PackItem {
  final int productId;
  final String productName;
  final int quantity; // Cantidad que lleva 1 unidad del pack

  PackItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}

class Pack {
  final int? id;
  final String name;
  final double price;
  final int units; // <--- Stock de unidades montadas de este pack
  final String? imagePath;
  final Uint8List? imageBytes; // <-- NUEVO: Para el binario de la foto del pack
  final List<PackItem> items;

  Pack({
    this.id,
    required this.name,
    required this.price,
    this.units = 1,
    this.imagePath,
    this.imageBytes, // <-- NUEVO
    required this.items,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
