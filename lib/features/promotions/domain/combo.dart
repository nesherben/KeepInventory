import 'dart:convert';

/// Hueco de un combo: un producto concreto ("1 × Teclado A") o, con
/// [categoryId], cualquier producto de una categoría ("1 × cualquier
/// Polaroid"; [productIds] son entonces los productos activos de esa
/// categoría, resueltos al cargar).
class ComboSlot {
  final int? id;
  final String name;
  final int quantity;
  final List<int> productIds;
  final int? categoryId;

  const ComboSlot({
    this.id,
    required this.name,
    this.quantity = 1,
    required this.productIds,
    this.categoryId,
  });

  bool get isCategory => categoryId != null;

  Map<String, Object?> toJson() => {
    'name': name,
    'quantity': quantity,
    'productIds': productIds,
    'categoryId': ?categoryId,
  };

  factory ComboSlot.fromJson(Map<String, Object?> json) => ComboSlot(
    name: json['name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    productIds: [
      for (final id in (json['productIds'] as List? ?? const []))
        (id as num).toInt(),
    ],
    categoryId: (json['categoryId'] as num?)?.toInt(),
  );
}

/// Combo: precio fijo por completar todos sus huecos (ej. teclado + ratón = 10 €).
/// No tiene stock propio; se detecta en el carrito con los productos sueltos.
class Combo {
  final int? id;
  final String name;
  final double price;
  final List<ComboSlot> slots;

  const Combo({
    this.id,
    required this.name,
    required this.price,
    required this.slots,
  });

  Set<int> get productIds => {for (final s in slots) ...s.productIds};

  /// Se puede vender: todos los huecos tienen producto (si uno se borró,
  /// el combo queda en pausa hasta editarlo).
  bool get isComplete =>
      slots.isNotEmpty && slots.every((s) => s.productIds.isNotEmpty);

  /// Lo que cuestan los productos por separado (el más caro de cada hueco).
  double separatePrice(double Function(int productId) priceOf) =>
      slots.fold(0.0, (t, slot) {
        final prices = [for (final id in slot.productIds) priceOf(id)]..sort();
        return t + (prices.isEmpty ? 0 : prices.last * slot.quantity);
      });

  /// Copia congelada de los huecos para guardarla con la venta.
  String encodeDefinition() => jsonEncode([for (final s in slots) s.toJson()]);

  static List<ComboSlot> decodeDefinition(String? json) {
    if (json == null || json.isEmpty) return const [];
    final list = jsonDecode(json) as List;
    return [
      for (final e in list)
        ComboSlot.fromJson(Map<String, Object?>.from(e as Map)),
    ];
  }
}
