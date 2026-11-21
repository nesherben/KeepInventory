/// Cálculo de las vueltas al cobrar en efectivo. Todo en céntimos enteros
/// para no arrastrar errores de coma flotante (0,1 + 0,2 ≠ 0,3).
abstract final class CashChange {
  /// Billetes habituales con los que se suele pagar.
  static const List<int> bills = [5, 10, 20, 50, 100, 200, 500];

  static int cents(double amount) => (amount * 100).round();

  /// Entregado − total, en céntimos: positivo = vueltas, negativo = falta.
  static int differenceCents(double total, double given) =>
      cents(given) - cents(total);

  /// Billetes que cubren el total, de menor a mayor (los más probables).
  static List<int> quickBills(double total, {int max = 4}) => [
    for (final bill in bills)
      if (cents(bill.toDouble()) >= cents(total)) bill,
  ].take(max).toList();
}
