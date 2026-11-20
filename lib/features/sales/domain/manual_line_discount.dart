/// Redondea un importe a céntimos (la lógica de dinero vive aquí, no en la UI).
double roundToCents(double value) => (value * 100).round() / 100;

/// Tipo de descuento manual de una línea del carrito.
enum ManualDiscountType {
  percent('percent'),
  amount('amount');

  const ManualDiscountType(this.dbValue);

  /// Valor guardado en `sale_items.manual_discount_type`.
  final String dbValue;

  static ManualDiscountType? fromDb(String? value) {
    for (final type in values) {
      if (type.dbValue == value) return type;
    }
    return null;
  }
}

/// Descuento manual ("ad hoc") sobre el TOTAL de una línea del carrito.
///
/// No toca el producto: vive en el carrito y se congela en la línea del
/// ticket. El "precio final" que teclea el vendedor se convierte a un importe
/// con [ManualLineDiscount.fromFinalPrice].
class ManualLineDiscount {
  final ManualDiscountType type;

  /// Porcentaje (0-100) o importe en euros, según [type].
  final double value;

  const ManualLineDiscount(this.type, this.value);

  const ManualLineDiscount.percent(double percent)
    : this(ManualDiscountType.percent, percent);

  const ManualLineDiscount.amount(double amount)
    : this(ManualDiscountType.amount, amount);

  /// "Lo dejo en [finalTotal]": importe que hay que restar a [lineTotal].
  factory ManualLineDiscount.fromFinalPrice({
    required double finalTotal,
    required double lineTotal,
  }) => ManualLineDiscount.amount(roundToCents(lineTotal - finalTotal));

  /// Importe que se resta a [lineTotal]: entre 0 y el propio total (el precio
  /// de la línea nunca baja de 0) y redondeado a céntimos.
  double discountOn(double lineTotal) {
    if (!lineTotal.isFinite || lineTotal <= 0 || !value.isFinite) return 0;
    final raw = type == ManualDiscountType.percent
        ? lineTotal * value / 100
        : value;
    return roundToCents(raw.clamp(0.0, lineTotal));
  }

  /// Total de la línea una vez aplicado el descuento.
  double apply(double lineTotal) =>
      roundToCents(lineTotal - discountOn(lineTotal));

  /// El mismo descuento expresado como porcentaje de [lineTotal] (2 decimales).
  /// Sirve para cambiar de modo en la hoja de descuento sin perder el valor.
  double percentOf(double lineTotal) {
    if (!lineTotal.isFinite || lineTotal <= 0) return 0;
    return roundToCents(discountOn(lineTotal) / lineTotal * 100);
  }

  @override
  bool operator ==(Object other) =>
      other is ManualLineDiscount && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);
}
