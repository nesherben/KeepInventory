import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/presentation/widgets/item_preview_info.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('updates quantity, stock, total, and combined promotion state', (
    tester,
  ) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    var addCalls = 0;
    var removeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: ItemPreviewInfo(
                title: 'Taza',
                unitPrice: '5.00 €',
                rawPrice: 5,
                cartTotal: 0,
                stock: 2,
                promoName: 'Oferta',
                promoThreshold: 2,
                otherItemsInPromo: 1,
                onAction: () => addCalls++,
                onRemoveAction: () => removeCalls++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(localizations.addToCart));
    await tester.pump();
    expect(addCalls, 1);
    expect(find.text(localizations.offerApplied), findsOneWidget);
    expect(find.text('5.00 €'), findsNWidgets(2));

    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(removeCalls, 1);
    expect(find.text(localizations.unitsRemaining('2')), findsOneWidget);
    expect(
      find.text(localizations.promotionShortfallCombined('0', '1')),
      findsOneWidget,
    );
  });
}
