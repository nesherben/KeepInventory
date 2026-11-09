import 'combo.dart';

/// Un combo aplicado [count] veces en el carrito.
class ComboApplication {
  final Combo combo;
  final int count;

  /// Unidades de cada producto que forman los combos.
  final Map<int, int> usedUnits;

  /// Parte del precio del combo que se asigna a cada producto (suma exacta).
  final Map<int, double> lineTotals;

  /// Lo que costarían esas unidades por separado.
  final double fullPrice;

  const ComboApplication({
    required this.combo,
    required this.count,
    required this.usedUnits,
    required this.lineTotals,
    required this.fullPrice,
  });

  double get total => lineTotals.values.fold(0.0, (t, v) => t + v);
  double get saving => fullPrice - total;
}

/// Combo a medio completar: sirve para la pista "falta Gorra".
class ComboHint {
  final Combo combo;
  final List<ComboSlot> missing;

  const ComboHint({required this.combo, required this.missing});

  int get filled => combo.slots.length - missing.length;
}

class ComboMatchResult {
  final List<ComboApplication> applications;

  /// Unidades que no forman combo (se cobran con su precio/promoción normal).
  final Map<int, int> remaining;
  final List<ComboHint> hints;

  const ComboMatchResult({
    required this.applications,
    required this.remaining,
    required this.hints,
  });

  static const empty = ComboMatchResult(
    applications: [],
    remaining: {},
    hints: [],
  );
}

/// Detecta combos en un conjunto de unidades. Lógica pura (sin Flutter).
///
/// Cada combo se aplica tantas veces como permita su hueco más escaso; en
/// cada hueco se usan primero las unidades más caras (como las promos de
/// lote). Un producto solo cuenta para un hueco: si por error estuviera en
/// varios, lo usa el primero que lo pida.
abstract final class ComboMatcher {
  static ComboMatchResult match({
    required List<Combo> combos,
    required Map<int, int> quantities,
    required double Function(int productId) priceOf,
  }) {
    final available = {
      for (final e in quantities.entries)
        if (e.value > 0) e.key: e.value,
    };
    final applications = <ComboApplication>[];

    for (final combo in combos) {
      if (combo.slots.isEmpty) continue;
      final claimed = <int>{};
      final slotProducts = <List<int>>[];
      for (final slot in combo.slots) {
        final ids = [
          for (final id in slot.productIds)
            if (claimed.add(id)) id,
        ];
        slotProducts.add(ids);
      }

      // Nº de combos = lo que permita el hueco con menos unidades
      var count = -1;
      for (var s = 0; s < combo.slots.length; s++) {
        final qty = combo.slots[s].quantity < 1 ? 1 : combo.slots[s].quantity;
        final units = slotProducts[s].fold<int>(
          0,
          (t, id) => t + (available[id] ?? 0),
        );
        final possible = units ~/ qty;
        if (count < 0 || possible < count) count = possible;
      }
      if (count <= 0) continue;

      final used = <int, int>{};
      for (var s = 0; s < combo.slots.length; s++) {
        final qty = combo.slots[s].quantity < 1 ? 1 : combo.slots[s].quantity;
        var need = qty * count;
        final ids =
            [
              for (final id in slotProducts[s])
                if ((available[id] ?? 0) > 0) id,
            ]..sort((a, b) {
              final byPrice = priceOf(b).compareTo(priceOf(a));
              return byPrice != 0 ? byPrice : a.compareTo(b);
            });
        for (final id in ids) {
          if (need == 0) break;
          final take = (available[id] ?? 0) < need
              ? (available[id] ?? 0)
              : need;
          if (take == 0) continue;
          used[id] = (used[id] ?? 0) + take;
          available[id] = available[id]! - take;
          need -= take;
        }
      }

      applications.add(
        ComboApplication(
          combo: combo,
          count: count,
          usedUnits: used,
          lineTotals: _allocate(combo.price * count, used, priceOf),
          fullPrice: used.entries.fold(
            0.0,
            (t, e) => t + priceOf(e.key) * e.value,
          ),
        ),
      );
    }

    final remaining = {
      for (final e in available.entries)
        if (e.value > 0) e.key: e.value,
    };
    return ComboMatchResult(
      applications: applications,
      remaining: remaining,
      hints: _hints(combos, remaining),
    );
  }

  /// Reparte [total] entre los productos en proporción a su precio normal,
  /// en céntimos y con la suma exacta (método del mayor resto).
  static Map<int, double> _allocate(
    double total,
    Map<int, int> used,
    double Function(int productId) priceOf,
  ) {
    final totalCents = (total * 100).round();
    final weights = {
      for (final e in used.entries) e.key: priceOf(e.key) * e.value,
    };
    var weightSum = weights.values.fold(0.0, (t, v) => t + v);
    if (weightSum <= 0) {
      // Todo a 0 €: reparto por unidades
      weights.updateAll((id, _) => used[id]!.toDouble());
      weightSum = weights.values.fold(0.0, (t, v) => t + v);
    }

    final cents = <int, int>{};
    final remainders = <int, double>{};
    var assigned = 0;
    for (final e in weights.entries) {
      final exact = totalCents * e.value / weightSum;
      cents[e.key] = exact.floor();
      remainders[e.key] = exact - exact.floor();
      assigned += exact.floor();
    }
    final order = remainders.keys.toList()
      ..sort((a, b) {
        final byRest = remainders[b]!.compareTo(remainders[a]!);
        return byRest != 0 ? byRest : a.compareTo(b);
      });
    for (var i = 0; i < totalCents - assigned; i++) {
      final id = order[i % order.length];
      cents[id] = cents[id]! + 1;
    }
    return {for (final e in cents.entries) e.key: e.value / 100};
  }

  static List<ComboHint> _hints(List<Combo> combos, Map<int, int> remaining) {
    final hints = <ComboHint>[];
    for (final combo in combos) {
      final missing = <ComboSlot>[];
      for (final slot in combo.slots) {
        final units = slot.productIds.fold<int>(
          0,
          (t, id) => t + (remaining[id] ?? 0),
        );
        if (units < (slot.quantity < 1 ? 1 : slot.quantity)) missing.add(slot);
      }
      if (missing.isNotEmpty && missing.length < combo.slots.length) {
        hints.add(ComboHint(combo: combo, missing: missing));
      }
    }
    return hints;
  }
}
