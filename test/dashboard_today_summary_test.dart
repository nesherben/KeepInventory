import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/dashboard/domain/dashboard_today_summary.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';

Sale _s(
  DateTime date,
  double total, {
  int? id,
  PaymentMethod method = PaymentMethod.cash,
}) => Sale(
  id: id,
  date: date,
  totalAmount: total,
  items: const [],
  paymentMethod: method,
);

Product _p(String name, int units) =>
    Product(name: name, units: units, price: 5, cost: 2);

void main() {
  final now = DateTime(2026, 11, 21, 15, 30);

  test('día sin ventas: ceros y sin último ticket', () {
    final r = DashboardTodaySummary.from(
      [_s(DateTime(2026, 11, 20, 12), 9)],
      [],
      now,
    );
    expect(r.total, 0);
    expect(r.ticketCount, 0);
    expect(r.lastTicket, isNull);
    expect(r.latestTickets, isEmpty);
  });

  test('23:59 y 00:00 cuentan como hoy; 23:59 de ayer no', () {
    final r = DashboardTodaySummary.from(
      [
        _s(DateTime(2026, 11, 21, 0, 0), 1),
        _s(DateTime(2026, 11, 21, 23, 59), 2),
        _s(DateTime(2026, 11, 20, 23, 59), 4),
        _s(DateTime(2026, 11, 22, 0, 0), 8),
      ],
      [],
      now,
    );
    expect(r.ticketCount, 2);
    expect(r.total, 3);
    expect(r.lastTicket!.date, DateTime(2026, 11, 21, 23, 59));
    expect(r.lastTicket!.amount, 2);
  });

  test('desglose por método solo con ventas de hoy', () {
    final r = DashboardTodaySummary.from(
      [
        _s(DateTime(2026, 11, 21, 9), 10),
        _s(DateTime(2026, 11, 21, 10), 5, method: PaymentMethod.bizum),
        _s(DateTime(2026, 11, 21, 11), 2.5, method: PaymentMethod.bizum),
        _s(DateTime(2026, 11, 20, 11), 99, method: PaymentMethod.paypal),
      ],
      [],
      now,
    );
    expect(r.byMethod[PaymentMethod.cash], 10);
    expect(r.byMethod[PaymentMethod.bizum], 7.5);
    expect(r.byMethod[PaymentMethod.paypal], 0);
  });

  test('últimos tickets: más reciente primero y máximo 5', () {
    final sales = [
      for (var h = 8; h < 15; h++)
        _s(DateTime(2026, 11, 21, h), h.toDouble(), id: h),
    ];
    final r = DashboardTodaySummary.from(sales, [], now);
    expect(r.ticketCount, 7);
    expect(r.latestTickets.length, 5);
    expect(r.latestTickets.first.id, 14);
    expect(r.latestTickets.last.id, 10);
  });

  test('por reponer: agotados primero y límites 0, 3 y 4 unidades', () {
    final r = DashboardTodaySummary.from([], [
      _p('ok', 4),
      _p('bajo3', 3),
      _p('agotado', 0),
      _p('bajo1', 1),
      _p('negativo', -1),
    ], now);
    expect(r.restock.map((p) => p.name), [
      'negativo',
      'agotado',
      'bajo1',
      'bajo3',
    ]);
    expect(r.outCount, 2);
  });
}
