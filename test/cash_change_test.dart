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
      expect(find.text('Vueltas'), findsOneWidget);
      expect(find.text('7,40 €'), findsOneWidget);

      await tester.tap(find.text('0,50 €'));
      await tester.pump();
      expect(find.text('7,90 €'), findsOneWidget);
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
      expect(find.text('Faltan 0,00 €'), findsNothing);
      expect(find.text('Vueltas'), findsOneWidget);
    });

    testWidgets('undo removes the last one and clear removes all', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('20,00 €'));
      await tester.tap(find.text('5,00 €'));
      await tester.pump();
      expect(find.text('12,40 €'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pump();
      expect(find.text('7,40 €'), findsOneWidget);

      await tester.tap(find.text('Borrar'));
      await tester.pump();
      expect(find.text('Faltan 12,60 €'), findsOneWidget);
    });

    testWidgets('"Justo" leaves nothing to give back', (tester) async {
      await open(tester);
      await tester.tap(find.text('Justo'));
      await tester.pump();
      expect(find.text('Vueltas'), findsOneWidget);
      expect(find.text('0,00 €'), findsOneWidget);
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
