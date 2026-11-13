import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sync/presentation/data_management_screen.dart';
import 'package:keepinventory/features/sync/presentation/widgets/slide_to_trash_sheet.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('es'));
  });

  group('SlideToTrash', () {
    Future<List<bool>> pumpSheet(WidgetTester tester) async {
      final results = <bool>[];
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async =>
                      results.add(await showSlideToTrashSheet(context)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('cancel closes the sheet without confirming', (tester) async {
      final results = await pumpSheet(tester);
      expect(find.text(l10n.trashSlideTitle), findsOneWidget);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.trashSlideTitle), findsNothing);
      expect(results, [false]);
    });

    testWidgets('releasing halfway snaps back and does not confirm', (
      tester,
    ) async {
      final results = await pumpSheet(tester);
      final thumb = find.byKey(SlideToTrash.thumbKey);
      final start = tester.getTopLeft(thumb);

      await tester.drag(thumb, const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(thumb).dx, closeTo(start.dx, 1));
      expect(find.text(l10n.trashSlideTitle), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('dropping into the bin confirms', (tester) async {
      final results = await pumpSheet(tester);

      await tester.drag(
        find.byKey(SlideToTrash.thumbKey),
        const Offset(2000, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.trashSlideTitle), findsNothing);
      expect(results, [true]);
    });
  });

  testWidgets('full deletion flow: two dialogs, then the bin; cancel at the '
      'bin keeps everything', (tester) async {
    await tester.pumpWidget(_app(const DataManagementScreen()));

    // El botón queda más abajo, tras las secciones de copias
    await tester.scrollUntilVisible(
      find.text(l10n.databaseDeleteTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(l10n.databaseDeleteTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.databaseDeleteTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.databaseDeleteContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.databaseDeleteConfirm));
    await tester.pumpAndSettle();

    // Tercer paso: la papelera
    expect(find.text(l10n.trashSlideTitle), findsOneWidget);
    expect(find.byKey(SlideToTrash.thumbKey), findsOneWidget);

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.trashSlideTitle), findsNothing);
    expect(find.text(l10n.databaseDeletedTitle), findsNothing);
  });
}
