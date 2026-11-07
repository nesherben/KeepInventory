import 'sale.dart';

/// Método con el que el cliente paga una venta.
/// Es solo informativo (no procesa cobros): sirve para el ticket, para
/// devolver por el mismo método y para cuadrar la caja por categoría.
enum PaymentMethod {
  cash('cash'),
  paypal('paypal'),
  bizum('bizum'),

  /// Ventas anteriores a la v12 (sin método registrado). No seleccionable.
  unspecified(null);

  const PaymentMethod(this.dbValue);

  /// Valor guardado en la columna `sales.payment_method` (NULL = sin especificar).
  final String? dbValue;

  static const PaymentMethod defaultMethod = PaymentMethod.cash;

  /// Métodos que se pueden elegir al cobrar.
  static const List<PaymentMethod> selectable = [cash, paypal, bizum];

  /// NULL o valores desconocidos se tratan como "sin especificar".
  static PaymentMethod fromDb(Object? value) => selectable.firstWhere(
    (m) => m.dbValue == value,
    orElse: () => unspecified,
  );

  /// Suma el importe de las ventas por método, con todos los métodos
  /// presentes (0 si no hay ventas) y en el orden del enum.
  static Map<PaymentMethod, double> totalsOf(Iterable<Sale> sales) {
    final totals = {for (final m in PaymentMethod.values) m: 0.0};
    for (final sale in sales) {
      totals[sale.paymentMethod] =
          totals[sale.paymentMethod]! + sale.totalAmount;
    }
    return totals;
  }
}
