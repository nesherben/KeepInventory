import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/app_preferences.dart';
import 'package:keepinventory/core/shared_widgets/app_side_rail.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget app() => MaterialApp(
    navigatorKey: appNavigatorKey,
    navigatorObservers: [appRouteObserver],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    builder: (context, child) => AppShell(child: child!),
    initialRoute: '/sales',
    routes: {
      '/sales': (_) => const Scaffold(body: Text('pantalla caja')),
      '/inventory': (_) => const Scaffold(body: Text('pantalla inventario')),
      '/tutorial': (_) => const Scaffold(body: Text('pantalla tutorial')),
    },
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appCurrentRoute.value = null;
    AppPreferences.railExpanded.value = false;
  });

  test('the rail only fits on tablets', () {
    expect(railFits(const Size(2560, 1600)), isTrue);
    expect(railFits(const Size(1200, 800)), isTrue);
    expect(railFits(const Size(412, 915)), isFalse);
    // Móvil en horizontal: ancho de sobra pero lado corto pequeño
    expect(railFits(const Size(900, 412)), isFalse);
  });

  testWidgets('tablet: icons rail, expands, navigates and hides on tutorial', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('pantalla caja'), findsOneWidget);
    expect(find.byIcon(Icons.point_of_sale), findsOneWidget);
    // Plegada: solo iconos, sin nombres
    expect(find.text('Inventario'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(AppPreferences.railExpanded.value, isTrue);
    expect(find.text('Inventario'), findsOneWidget);

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();
    expect(find.text('pantalla inventario'), findsOneWidget);

    appNavigatorKey.currentState!.pushNamed('/tutorial');
    await tester.pumpAndSettle();
    expect(find.text('pantalla tutorial'), findsOneWidget);
    expect(find.text('Inventario'), findsNothing);
  });

  testWidgets('phone: no rail', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('pantalla caja'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });
}
