import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/shared_widgets/app_drawer.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('unnamed submenu does not select Home and Home navigates there', (
    tester,
  ) async {
    const locale = Locale('es');
    final l10n = await AppLocalizations.delegate.load(locale);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir submenú'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text(l10n.navDashboard), findsOneWidget);
    expect(find.byIcon(Icons.home), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.text(l10n.navDashboard));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de inicio'), findsOneWidget);
    expect(find.text('Submenú'), findsNothing);
  });
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inicio')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pantalla de inicio'),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const _SubmenuScreen(),
              ),
            ),
            child: const Text('Abrir submenú'),
          ),
        ],
      ),
    ),
  );
}

class _SubmenuScreen extends StatelessWidget {
  const _SubmenuScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Submenú')),
    drawer: const AppDrawer(),
    body: const Center(child: Text('Submenú')),
  );
}
