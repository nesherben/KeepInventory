import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/app_preferences.dart';
import 'package:keepinventory/core/shared_widgets/coach_marks.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const locale = Locale('es');
  final first = GlobalKey();
  final second = GlobalKey();
  final missing = GlobalKey();

  Widget host(Widget Function(BuildContext) body) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: body)),
  );

  Widget targets(BuildContext context, VoidCallback onStart) => Column(
    children: [
      Container(key: first, width: 100, height: 40, color: Colors.blue),
      Container(key: second, width: 100, height: 40, color: Colors.green),
      TextButton(onPressed: onStart, child: const Text('Empezar')),
    ],
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferences.coachSeen.clear();
    AppPreferences.tutorialSeen = true;
  });

  testWidgets('walks the steps and closes on the last one', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      host(
        (context) => targets(context, () async {
          await CoachMarks.show(
            context,
            steps: [
              CoachStep(target: first, text: 'Primer paso'),
              CoachStep(target: second, title: 'Titulo', text: 'Segundo paso'),
            ],
          );
          finished = true;
        }),
      ),
    );

    await tester.tap(find.text('Empezar'));
    await settle(tester);

    expect(find.text('Primer paso'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await settle(tester);

    expect(find.text('Segundo paso'), findsOneWidget);
    expect(find.text('Titulo'), findsOneWidget);
    // El último paso no ofrece saltar y cierra con "Entendido"
    expect(find.text('Saltar'), findsNothing);
    expect(finished, isFalse);

    await tester.tap(find.text('Entendido'));
    await settle(tester);

    expect(find.text('Segundo paso'), findsNothing);
    expect(finished, isTrue);
  });

  testWidgets('skip closes the whole guide', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      host(
        (context) => targets(context, () async {
          await CoachMarks.show(
            context,
            steps: [
              CoachStep(target: first, text: 'Primer paso'),
              CoachStep(target: second, text: 'Segundo paso'),
            ],
          );
          finished = true;
        }),
      ),
    );

    await tester.tap(find.text('Empezar'));
    await settle(tester);
    await tester.tap(find.text('Saltar'));
    await settle(tester);

    expect(find.text('Primer paso'), findsNothing);
    expect(finished, isTrue);
  });

  testWidgets('steps whose element is not on screen are skipped', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        (context) => targets(context, () {
          CoachMarks.show(
            context,
            steps: [
              CoachStep(target: missing, text: 'No existe'),
              CoachStep(target: second, text: 'Este sí'),
            ],
          );
        }),
      ),
    );

    await tester.tap(find.text('Empezar'));
    await settle(tester);

    expect(find.text('No existe'), findsNothing);
    expect(find.text('Este sí'), findsOneWidget);
  });

  testWidgets('a guide with no element on screen shows nothing', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      host(
        (context) => targets(context, () async {
          await CoachMarks.show(
            context,
            steps: [CoachStep(target: missing, text: 'No existe')],
          );
          finished = true;
        }),
      ),
    );

    await tester.tap(find.text('Empezar'));
    await settle(tester);

    expect(find.text('No existe'), findsNothing);
    expect(finished, isTrue);
  });

  testWidgets('taps outside the highlight do not reach the screen below', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      host(
        (context) => Column(
          children: [
            SizedBox(key: first, width: 100, height: 40),
            TextButton(
              onPressed: () {
                pressed++;
                CoachMarks.show(
                  context,
                  steps: [CoachStep(target: first, text: 'Guía')],
                );
              },
              child: const Text('Empezar'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Empezar'));
    await settle(tester);
    expect(pressed, 1);

    // El botón de debajo queda tapado por la capa oscura
    await tester.tap(find.text('Empezar'), warnIfMissed: false);
    await settle(tester);

    expect(pressed, 1);
  });

  testWidgets('dismissAll closes an open guide', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      host(
        (context) => targets(context, () async {
          await CoachMarks.show(
            context,
            steps: [CoachStep(target: first, text: 'Primer paso')],
          );
          finished = true;
        }),
      ),
    );
    await tester.tap(find.text('Empezar'));
    await settle(tester);
    expect(find.text('Primer paso'), findsOneWidget);

    CoachMarks.dismissAll();
    await settle(tester);

    expect(find.text('Primer paso'), findsNothing);
    expect(finished, isTrue);
  });

  group('CoachGuide', () {
    testWidgets('shows once, remembers it, and can be replayed', (
      tester,
    ) async {
      var starts = 0;
      await tester.pumpWidget(
        host(
          (context) => targets(context, () async {
            await CoachGuide.showOnce(context, 'inventory', () {
              starts++;
              return [CoachStep(target: first, text: 'Guía de inventario')];
            });
          }),
        ),
      );

      await tester.tap(find.text('Empezar'));
      await settle(tester);
      expect(find.text('Guía de inventario'), findsOneWidget);
      expect(AppPreferences.isCoachSeen('inventory'), isTrue);

      await tester.tap(find.text('Entendido'));
      await settle(tester);

      // Segunda vez: ya vista, no sale
      await tester.tap(find.text('Empezar'));
      await settle(tester);
      expect(find.text('Guía de inventario'), findsNothing);
      expect(starts, 1);
    });

    testWidgets('does not show before the welcome tutorial is seen', (
      tester,
    ) async {
      AppPreferences.tutorialSeen = false;
      await tester.pumpWidget(
        host(
          (context) => targets(context, () async {
            await CoachGuide.showOnce(context, 'sales', () {
              return [CoachStep(target: first, text: 'Guía de caja')];
            });
          }),
        ),
      );

      await tester.tap(find.text('Empezar'));
      await settle(tester);

      expect(find.text('Guía de caja'), findsNothing);
      expect(AppPreferences.isCoachSeen('sales'), isFalse);
    });
  });

  group('AppPreferences guides', () {
    test('seen guides persist across loads and can be reset', () async {
      await AppPreferences.markCoachSeen('sales');
      await AppPreferences.markCoachSeen('inventory');

      AppPreferences.coachSeen.clear();
      await AppPreferences.load();
      expect(AppPreferences.coachSeen, {'sales', 'inventory'});

      await AppPreferences.resetCoachGuides();
      expect(AppPreferences.coachSeen, isEmpty);
      AppPreferences.coachSeen.add('x');
      await AppPreferences.load();
      expect(AppPreferences.coachSeen, isEmpty);
    });
  });
}
