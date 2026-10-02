import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/packs/presentation/widgets/pack_form_dialog.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('pack form renders in portrait and landscape', (tester) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    Future<void> pumpForm() {
      return tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: PackFormDialog(
                availableProducts: const [],
                onSave: (_) async {},
              ),
            ),
          ),
        ),
      );
    }

    tester.view.physicalSize = const Size(800, 600);
    await pumpForm();
    expect(find.text(localizations.packName), findsOneWidget);
    expect(find.text(localizations.packComponents), findsOneWidget);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(find.text(localizations.packName), findsOneWidget);
    expect(find.text(localizations.packComponents), findsOneWidget);

    tester.view.physicalSize = const Size(400, 500);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(localizations.packComponents), findsOneWidget);
  });
}
