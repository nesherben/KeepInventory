import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/cash_change.dart';
import 'package:keepinventory/features/sales/presentation/widgets/cash_change_sheet.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  group('CashChange', () {
    test('sums the bills and coins entered, in cents', () {
      expect(CashChange.sum([2000, 50, 5]), 2055);
      expect(CashChange.sum(const []), 0);
    });

    test('change is given minus total', () {
      expect(CashChange.differenceCents(12.6, 2000), 740);
      expect(CashChange.differenceCents(12.6, 1260), 0);
    });

    test('a shortfall is negative', () {
      expect(CashChange.differenceCents(12.6, 1000), -260);
    });

    test('floating point noise does not leak into the cents', () {
      // 0,1 + 0,2 no es exactamente 0,3 en coma flotante
      expect(CashChange.differenceCents(0.1 + 0.2, 30), 0);
      expect(CashChange.differenceCents(19.99, 2000), 1);
    });

    test('breaks the change down into the fewest bills and coins', () {
      expect(CashChange.breakdown(740), {500: 1, 200: 1, 20: 2});
      expect(CashChange.breakdown(2750), {2000: 1, 500: 1, 200: 1, 50: 1});
      // Incluye céntimos sueltos: 0,03 = 0,02 + 0,01
      expect(CashChange.breakdown(3), {2: 1, 1: 1});
      expect(CashChange.breakdown(0), isEmpty);
      expect(CashChange.breakdown(-50), isEmpty);
    });

    test('the breakdown always adds up to the change', () {
      for (final cents in [1, 7, 99, 740, 1234, 29999]) {
        final pieces = CashChange.breakdown(cents);
        final total = pieces.entries.fold<int>(
          0,
          (sum, e) => sum + e.key * e.value,
        );
        expect(total, cents);
      }
    });

    test('offers the euro bills and coins', () {
      expect(CashChange.billCents.first, 500);
      expect(CashChange.billCents.last, 20000);
      expect(CashChange.coinCents.first, 5);
      expect(CashChange.coinCents.last, 200);
    });
  });

  group('CashChangeSheet', () {
    Future<void> open(WidgetTester tester, {bool? expectCheckout}) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final checkout = await showCashChangeSheet(
                    context,
                    total: 12.6,
                  );
                  if (expectCheckout != null) {
                    expect(checkout, expectCheckout);
                  }
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('starts by showing what is still missing', (tester) async {
      await open(tester);
      expect(find.text('Faltan 12,60 €'), findsOneWidget);
    });

    testWidgets('tapping bills and coins adds them up', (tester) async {
      await open(tester);

      await tester.tap(find.text('20,00 €'));
      await tester.pump();
      expect(find.text('7,40 €'), findsOneWidget);

      await tester.tap(find.text('0,50 €'));
      await tester.pump();
      expect(find.text('7,90 €'), findsOneWidget);
    });

    testWidgets('says which bills and coins to give back', (tester) async {
      await open(tester);
      await tester.tap(find.text('20,00 €'));
      await tester.pump();

      // 7,40 € = 1 billete de 5 + 1 moneda de 2 + 2 monedas de 0,20
      expect(find.text('1 × 5,00 €'), findsOneWidget);
      expect(find.text('1 × 2,00 €'), findsOneWidget);
      expect(find.text('2 × 0,20 €'), findsOneWidget);
    });

    testWidgets('several small ones can add up to the total', (tester) async {
      await open(tester);
      await tester.tap(find.text('10,00 €'));
      await tester.pump();
      expect(find.text('Faltan 2,60 €'), findsOneWidget);

      await tester.tap(find.text('2,00 €'));
      await tester.tap(find.text('0,50 €'));
      await tester.tap(find.text('0,10 €'));
      await tester.pump();
      // 10 + 2 + 0,50 + 0,10 = 12,60: justo, sin nada que devolver
      expect(find.textContaining('Faltan'), findsNothing);
      expect(find.text('0,00 €'), findsOneWidget);
    });

    testWidgets('a wrong piece can be removed one by one', (tester) async {
      await open(tester);
      await tester.tap(find.text('20,00 €'));
      await tester.tap(find.text('20,00 €'));
      await tester.tap(find.text('5,00 €'));
      await tester.pump();
      // Lo marcado sale agrupado
      expect(find.text('2 × 20,00 €'), findsOneWidget);
      expect(find.text('1 × 5,00 €'), findsWidgets);

      // Quitar solo uno de los billetes de 20
      await tester.tap(find.byTooltip('Quitar uno').first);
      await tester.pump();
      expect(find.text('1 × 20,00 €'), findsOneWidget);
      expect(find.text('2 × 20,00 €'), findsNothing);
      // 20 + 5 = 25 → 12,40 € de vueltas
      expect(find.text('12,40 €'), findsOneWidget);
    });

    testWidgets('undo removes the last one and clear removes all', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('20,00 €'));
      await tester.tap(find.text('5,00 €'));
      await tester.pump();
      expect(find.text('12,40 €'), findsOneWidget);

      await tester.tap(find.byTooltip('Deshacer'));
      await tester.pump();
      expect(find.text('7,40 €'), findsOneWidget);

      await tester.tap(find.byTooltip('Borrar'));
      await tester.pump();
      expect(find.text('Faltan 12,60 €'), findsOneWidget);
    });

    testWidgets('"Justo" leaves nothing to give back', (tester) async {
      await open(tester);
      await tester.tap(find.text('Justo'));
      await tester.pump();
      expect(find.text('0,00 €'), findsOneWidget);
      // Solo el chip de lo entregado; sin piezas que devolver
      expect(find.textContaining('×'), findsOneWidget);
      expect(find.text('1 × 12,60 €'), findsOneWidget);
    });

    testWidgets('COBRAR inside the calculator reports a checkout', (
      tester,
    ) async {
      await open(tester, expectCheckout: true);
      await tester.tap(find.text('COBRAR'));
      await tester.pumpAndSettle();
      expect(find.text('Calcular vueltas'), findsNothing);
    });
  });
}
