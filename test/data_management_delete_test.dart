import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sync/presentation/data_management_screen.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'requires two confirmations and allows cancelling the final one',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DataManagementScreen(),
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      await tester.tap(find.widgetWithText(ListTile, l10n.databaseDeleteTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.databaseDeleteWarning), findsOneWidget);
      await tester.tap(find.text(l10n.databaseDeleteContinue));
      await tester.pumpAndSettle();

      expect(find.text(l10n.databaseDeleteFinalTitle), findsOneWidget);
      expect(find.text(l10n.databaseDeleteFinalWarning), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.databaseDeleteFinalTitle), findsNothing);
      expect(find.text(l10n.databaseDeleteTitle), findsOneWidget);
    },
  );
}
