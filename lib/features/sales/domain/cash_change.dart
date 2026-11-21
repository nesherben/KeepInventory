/// Cálculo de las vueltas al cobrar en efectivo. Todo en céntimos enteros
/// para no arrastrar errores de coma flotante (0,1 + 0,2 ≠ 0,3).
abstract final class CashChange {
  /// Billetes de euro que se pueden marcar (en céntimos).
  static const List<int> billCents = [500, 1000, 2000, 5000, 10000, 20000];

  /// Monedas de euro que se pueden marcar (en céntimos).
  static const List<int> coinCents = [5, 10, 20, 50, 100, 200];

  static int cents(double amount) => (amount * 100).round();

  /// Entregado − total, en céntimos: positivo = vueltas, negativo = falta.
  static int differenceCents(double total, int givenCents) =>
      givenCents - cents(total);

  /// Suma de lo marcado (billetes y monedas), en céntimos.
  static int sum(Iterable<int> entries) =>
      entries.fold(0, (total, cents) => total + cents);
}
