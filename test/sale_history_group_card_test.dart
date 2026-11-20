import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/sales/domain/sale.dart';
import 'package:keepinventory/features/sales/presentation/sale_history_group.dart';
import 'package:keepinventory/features/sales/presentation/widgets/sale_history_group_card.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('group card forwards fair and refund actions', (tester) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    final sale = Sale(
      id: 8,
      date: DateTime(2026, 10, 2, 14, 5),
      totalAmount: 10,
      fairName: 'Autumn Fair',
      items: [
        SaleItem(
          productId: 1,
          productName: 'Taza',
          quantity: 2,
          historicalPrice: 4,
          originalPrice: 5,
        ),
      ],
    );
    final group = SaleHistoryGroup(
      key: 'fair:Autumn Fair',
      datePrefix: '2026-10-02',
      sales: [sale],
    );
    String? assignedDate;
    String? assignedFair;
    Sale? refundedSale;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SaleHistoryGroupCard(
            group: group,
            onAssignFair: (date, fair) {
              assignedDate = date;
              assignedFair = fair;
            },
            onRefund: (sale) => refundedSale = sale,
          ),
        ),
      ),
    );

    expect(find.text(group.label), findsOneWidget);
    await tester.tap(find.text(localizations.changeFair));
    await tester.pump();
    expect(assignedDate, '2026-10-02');
    expect(assignedFair, 'Autumn Fair');

    await tester.tap(find.text(localizations.ticketTitle('8')));
    await tester.pumpAndSettle();
    final originalPriceFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data?.contains('10,00') == true &&
          widget.style?.decoration == TextDecoration.lineThrough,
    );
    expect(originalPriceFinder, findsOneWidget);
    final originalPrice = tester.widget<Text>(originalPriceFinder);
    expect(
      originalPrice.style?.color,
      // El rojo se reserva a borrar: el precio tachado va neutro
      Theme.of(tester.element(originalPriceFinder))
          .colorScheme
          .onSurfaceVariant,
    );
    await tester.tap(find.text(localizations.refund));
    await tester.pump();
    expect(refundedSale, sale);
  });

  testWidgets('shows the manual discount label on a discounted line', (
    tester,
  ) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    final sale = Sale(
      id: 9,
      date: DateTime(2026, 10, 2, 14, 5),
      totalAmount: 9,
      items: [
        SaleItem(
          productId: 1,
          productName: 'Camiseta',
          quantity: 1,
          historicalPrice: 9,
          originalPrice: 10,
          manualDiscountType: ManualDiscountType.percent,
          manualDiscountValue: 10,
        ),
      ],
    );
    final group = SaleHistoryGroup(
      key: 'day:2026-10-02',
      datePrefix: '2026-10-02',
      sales: [sale],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SaleHistoryGroupCard(
              group: group,
              onAssignFair: (_, _) {},
              onRefund: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(localizations.ticketTitle('9')));
    await tester.pumpAndSettle();

    expect(find.text(localizations.lineDiscountTag('−10 %')), findsOneWidget);
    expect(find.text(localizations.discountApplied), findsNothing);
  });
}
