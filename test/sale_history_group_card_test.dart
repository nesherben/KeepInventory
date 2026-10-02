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
          historicalPrice: 5,
        ),
      ],
    );
    final group = SaleHistoryGroup(
      key: '🎪 Autumn Fair',
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

    expect(find.text(group.key), findsOneWidget);
    await tester.tap(find.text(localizations.changeFair));
    await tester.pump();
    expect(assignedDate, '2026-10-02');
    expect(assignedFair, 'Autumn Fair');

    await tester.tap(find.text(localizations.ticketTitle('8')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.refund));
    await tester.pump();
    expect(refundedSale, sale);
  });
}
