import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';
import 'package:keepinventory/features/inventory/presentation/widgets/inventory_products_table.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('table forwards product edit actions', (tester) async {
    const locale = Locale('es');
    final localizations = await AppLocalizations.delegate.load(locale);
    final product = Product(id: 1, name: 'Taza', units: 4, price: 5, cost: 2);
    Product? editedProduct;
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: InventoryProductsTable(
              products: [product],
              promotions: const {},
              onEditProduct: (value) => editedProduct = value,
              onDeleteProduct: (_) {},
              onEditImage: (_) {},
              onEditField: (_, _) {},
              onStockChange: (_, _) {},
              onEditPromotion: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(localizations.tableName), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.editAll));
    await tester.pumpAndSettle();

    expect(editedProduct, product);
  });
}
