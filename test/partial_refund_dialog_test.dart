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
    expect(refundField.controller!.text, '5.00');

    await tester.tap(find.text(localizations.confirm));
    await tester.pumpAndSettle();

    expect(submittedItems, {item: 1});
    expect(submittedAmount, 5);
  });
}
