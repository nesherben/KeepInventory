import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:keepinventory/features/sales/presentation/widgets/partial_refund_dialog.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('recalculates the refund and submits selected quantities', (
    tester,
  ) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    final item = SaleItem(
      productId: 1,
      productName: 'Taza',
      quantity: 2,
      historicalPrice: 5,
      originalPrice: 5,
    );
    Map<SaleItem, int>? submittedItems;
    double? submittedAmount;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PartialRefundDialog(
                  sale: Sale(
                    id: 1,
                    date: DateTime(2026, 10, 2),
                    totalAmount: 10,
                    items: [item],
                  ),
                  onConfirm:
                      ({
                        required itemsToRefund,
                        required packsToRefund,
                        required restockAsComponents,
                        required customRefundAmount,
                      }) async {
                        submittedItems = itemsToRefund;
                        submittedAmount = customRefundAmount;
                      },
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    final refundField = tester.widget<TextField>(find.byType(TextField));
    expect(refundField.controller!.text, '5,00');
    expect(
      find.textContaining(localizations.salesRefundOriginalUnitPrice('5,00')),
      findsOneWidget,
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '3.2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(refundField.controller!.text, '3,20');

    await tester.tap(find.text(localizations.confirm));
    await tester.pumpAndSettle();

    expect(submittedItems, {item: 1});
    expect(submittedAmount, 3.2);
  });

  testWidgets('a line with a manual discount cannot be refunded', (
    tester,
  ) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    final discounted = SaleItem(
      productId: 1,
      productName: 'Camiseta',
      quantity: 2,
      historicalPrice: 9,
      originalPrice: 10,
      manualDiscountType: ManualDiscountType.percent,
      manualDiscountValue: 10,
    );
    final plain = SaleItem(
      productId: 2,
      productName: 'Taza',
      quantity: 1,
      historicalPrice: 5,
      originalPrice: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PartialRefundDialog(
            sale: Sale(
              id: 1,
              date: DateTime(2026, 10, 2),
              totalAmount: 23,
              items: [discounted, plain],
            ),
            onConfirm: ({
              required itemsToRefund,
              required packsToRefund,
              required restockAsComponents,
              required customRefundAmount,
            }) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Las líneas con descuento manual van en su propio bloque, sin selector
    expect(
      find.text(localizations.refundBlockedManualDiscount.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Descuento −10 %'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    // Solo la línea que sí se puede devolver tiene botones + y −
    final addButtons = find.widgetWithIcon(IconButton, Icons.add);
    expect(addButtons, findsOneWidget);
    expect(tester.widget<IconButton>(addButtons).onPressed, isNotNull);
  });
}
