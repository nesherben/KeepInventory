// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keepinventory/core/services/app_preferences.dart';
import 'package:keepinventory/features/dashboard/presentation/widgets/dashboard_chart.dart';
import 'package:keepinventory/features/sales/domain/payment_method.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('chart details toggles privacy mode', (tester) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FullScreenChartScreen(
          dailySales: {'2026-10-02': 10},
          dailyNetProfits: {'2026-10-02': 3},
        ),
      ),
    );

    expect(find.text(localizations.chartDetailsTitle), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FullScreenChartScreen(
          dailySales: {'2026-10-02': 10},
          dailyNetProfits: {'2026-10-02': 3},
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    // Con privacidad activa no se ve ningún importe
    expect(find.text('10.00 €'), findsNothing);
    expect(find.textContaining('••••••'), findsWidgets);
  });

  testWidgets('chart shows payment breakdown, selection and filter', (
    tester,
  ) async {
    AppPreferences.privacyModeEnabled.value = false;
    // Pantalla alta para que el detalle y el historial estén construidos
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const locale = Locale('es');
    final l10n = await AppLocalizations.delegate.load(locale);
    final dayTitle = l10n.chartDayTitle('02/10/2026');
    final fairTitle = l10n.chartFairTitle('Feria Otoño');

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FullScreenChartScreen(
          dailySales: {'2026-10-02': 10, 'Feria Otoño': 20},
          dailyNetProfits: {'2026-10-02': 3, 'Feria Otoño': 8},
          revenueByMethodPerGroup: {
            '2026-10-02': {PaymentMethod.cash: 6, PaymentMethod.bizum: 4},
            'Feria Otoño': {PaymentMethod.paypal: 20},
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Por defecto se selecciona el último grupo (la feria): solo PayPal en el
    // detalle; "Efectivo" aparece una vez (leyenda).
    expect(find.text(fairTitle), findsNWidgets(2)); // detalle + historial
    expect(find.text('Efectivo'), findsOneWidget);

    // Tocar el día en el historial lo selecciona y muestra su desglose
    await tester.tap(find.text(dayTitle));
    await tester.pumpAndSettle();
    expect(find.text(dayTitle), findsNWidgets(2));
    expect(find.text('Efectivo'), findsNWidgets(2)); // leyenda + detalle
    expect(find.text('60.0 %'), findsOneWidget);

    // Filtro "Ferias": el día desaparece
    await tester.tap(find.text(l10n.chartFairs));
    await tester.pumpAndSettle();
    expect(find.text(dayTitle), findsNothing);
    expect(find.text(fairTitle), findsNWidgets(2));
  });
}
