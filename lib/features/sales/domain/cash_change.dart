/// Cálculo de las vueltas al cobrar en efectivo. Todo en céntimos enteros
/// para no arrastrar errores de coma flotante (0,1 + 0,2 ≠ 0,3).
abstract final class CashChange {
  /// Billetes de euro que se pueden marcar (en céntimos).
  static const List<int> billCents = [500, 1000, 2000, 5000, 10000, 20000];

  /// Monedas de euro que se pueden marcar (en céntimos).
  static const List<int> coinCents = [5, 10, 20, 50, 100, 200];

  /// Billetes y monedas con los que se devuelven las vueltas, de mayor a menor
  /// (incluye las de 1 y 2 céntimos para poder devolver cualquier importe).
  static const List<int> changeDenominations = [
    20000, 10000, 5000, 2000, 1000, 500, //
    200, 100, 50, 20, 10, 5, 2, 1,
  ];

  static int cents(double amount) => (amount * 100).round();

  /// Entregado − total, en céntimos: positivo = vueltas, negativo = falta.
  static int differenceCents(double total, int givenCents) =>
      givenCents - cents(total);

  /// Suma de lo marcado (billetes y monedas), en céntimos.
  static int sum(Iterable<int> entries) =>
      entries.fold(0, (total, cents) => total + cents);

  /// Con qué billetes y monedas devolver [changeCents]: pieza → cantidad, de
  /// mayor a menor y con el menor número de piezas.
  static Map<int, int> breakdown(int changeCents) {
    final result = <int, int>{};
    var rest = changeCents;
    if (rest <= 0) return result;
    for (final piece in changeDenominations) {
      final count = rest ~/ piece;
      if (count > 0) {
        result[piece] = count;
        rest -= count * piece;
      }
    }
    return result;
  }
}
