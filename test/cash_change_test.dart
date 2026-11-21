import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/cash_change.dart';
import 'package:keepinventory/features/sales/presentation/widgets/cash_change_calculator.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  group('CashChange', () {
    test('change is given minus total in cents', () {
      expect(CashChange.differenceCents(12.6, 20), 740);
      expect(CashChange.differenceCents(12.6, 12.6), 0);
    });

    test('a shortfall is negative', () {
      expect(CashChange.differenceCents(12.6, 10), -260);
    });

    test('floating point noise does not leak into the cents', () {
      // 0,1 + 0,2 no es exactamente 0,3 en coma flotante
      expect(CashChange.differenceCents(0.1 + 0.2, 0.3), 0);
      expect(CashChange.differenceCents(19.99, 20), 1);
    });

    test('quick bills are the smallest ones that cover the total', () {
      expect(CashChange.quickBills(12.6), [20, 50, 100, 200]);
      expect(CashChange.quickBills(3), [5, 10, 20, 50]);
      expect(CashChange.quickBills(20), [20, 50, 100, 200]);
      expect(CashChange.quickBills(20.01), [50, 100, 200, 500]);
      expect(CashChange.quickBills(600), isEmpty);
    });
  });

  group('CashChangeCalculator', () {
    Widget app() => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: CashChangeCalculator(total: 12.6)),
    );

    testWidgets('a bill chip shows the change to give back', (tester) async {
      await tester.pumpWidget(app());
      expect(find.text('Vueltas'), findsNothing);

      await tester.tap(find.text('20,00 €'));
      await tester.pump();

      expect(find.text('Vueltas'), findsOneWidget);
      expect(find.text('7,40 €'), findsOneWidget);
    });

    testWidgets('"Justo" means no change', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Justo'));
      await tester.pump();
      expect(find.text('0,00 €'), findsOneWidget);
    });

    testWidgets('typing less than the total shows what is missing', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.enterText(find.byType(TextField), '10');
      await tester.pump();
      expect(find.text('Faltan 2,60 €'), findsOneWidget);
      expect(find.text('Vueltas'), findsNothing);
    });

    testWidgets('typing decimals with a comma works', (tester) async {
      await tester.pumpWidget(app());
      await tester.enterText(find.byType(TextField), '15,10');
      await tester.pump();
      expect(find.text('2,50 €'), findsOneWidget);
    });
  });
}
