class Promotion {
  final int? id;
  final String name;
  final String
  type; // 'bundle_fixed_price' (ej: 3 por 12€) o 'percentage' (ej: 10% dto)
  final int threshold; // Cantidad mínima para que se aplique (ej: 3)
  final double
  discountValue; // El valor (ej: 12.0 para el pack, o 10.0 para el 10%)

  Promotion({
    this.id,
    required this.name,
    required this.type,
    required this.threshold,
    required this.discountValue,
  });
}
