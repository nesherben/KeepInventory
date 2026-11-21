import '../../inventory/domain/inventory_view.dart';
import '../../inventory/domain/product.dart';
import '../../sales/domain/sale.dart';

/// Último ticket del día (hora e importe).
class TodayTicket {
  const TodayTicket({
    required this.id,
    required this.date,
    required this.amount,
  });

  final int? id;
  final DateTime date;
  final double amount;
}

/// Cifras de "hoy" y lista de productos por reponer para el Inicio del móvil.
/// Lógica pura: se calcula en Dart desde las ventas y productos ya cargados.
class DashboardTodaySummary {
  DashboardTodaySummary._({
    required this.total,
    required this.ticketCount,
    required this.byMethod,
    required this.latestTickets,
    required this.restock,
    required this.outCount,
  });

  /// Total cobrado hoy (las devoluciones ya están descontadas en el total).
  final double total;
  final int ticketCount;

  /// Importe de hoy por método de pago (todos los métodos, 0 si no hay).
  final Map<PaymentMethod, double> byMethod;

  /// Tickets de hoy, del más reciente al más antiguo (máximo [maxTickets]).
  final List<TodayTicket> latestTickets;

  /// Productos con stock bajo o agotado, los agotados primero.
  final List<Product> restock;
  final int outCount;

  static const int maxTickets = 5;

  TodayTicket? get lastTicket =>
      latestTickets.isEmpty ? null : latestTickets.first;

  /// Los límites del día son locales (las fechas se guardan sin zona horaria).
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  factory DashboardTodaySummary.from(
    List<Sale> sales,
    List<Product> products,
    DateTime now,
  ) {
    final today = sales.where((s) => isSameDay(s.date, now)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final byMethod = PaymentMethod.totalsOf(today);
    final restock =
        products.where((p) => StockLevel.of(p.units) != StockLevel.ok).toList()
          ..sort((a, b) {
            final byLevel = (StockLevel.of(a.units) == StockLevel.out ? 0 : 1)
                .compareTo(StockLevel.of(b.units) == StockLevel.out ? 0 : 1);
            if (byLevel != 0) return byLevel;
            final byUnits = a.units.compareTo(b.units);
            return byUnits != 0
                ? byUnits
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    return DashboardTodaySummary._(
      total: today.fold(0.0, (t, s) => t + s.totalAmount),
      ticketCount: today.length,
      byMethod: byMethod,
      latestTickets: [
        for (final s in today.take(maxTickets))
          TodayTicket(id: s.id, date: s.date, amount: s.totalAmount),
      ],
      restock: restock,
      outCount: restock
          .where((p) => StockLevel.of(p.units) == StockLevel.out)
          .length,
    );
  }
}
