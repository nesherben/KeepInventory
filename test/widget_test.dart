// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keepinventory/features/dashboard/presentation/widgets/dashboard_chart.dart';
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
    expect(find.text('••€'), findsOneWidget);
  });
}
