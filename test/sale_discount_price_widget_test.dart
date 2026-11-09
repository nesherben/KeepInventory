import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/inventory/domain/product.dart';
import 'package:keepinventory/features/packs/domain/pack.dart';
import 'package:keepinventory/features/promotions/domain/promotion.dart';
import 'package:keepinventory/features/sales/domain/sale_cart_pricing_calculator.dart';
import 'package:keepinventory/features/sales/presentation/widgets/cart_items_list_widget.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows original and discounted cart totals', (tester) async {
    final product = Product(
      id: 1,
      name: 'Taza',
      units: 10,
      price: 10,
      cost: 5,
      promotionId: 1,
    );
    final promotion = Promotion(
      id: 1,
      name: 'Oferta',
      type: 'percentage',
      threshold: 2,
      discountValue: 20,
    );
    final cart = {product: 2};
    final promotions = {1: promotion};

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: CartItemsListWidget(
              cart: cart,
              cartPacks: const <Pack, int>{},
              promotionsMap: promotions,
              pricing: SaleCartPricingCalculator.price(
                products: cart,
                packs: const {},
                promotions: promotions,
              ),
              onRemoveFromCart: (_) {},
              onRemoveAllFromCart: (_) {},
              onRemovePackFromCart: (_) {},
              onRemoveAllPackFromCart: (_) {},
            ),
          ),
        ),
      ),
    );

    final originalPriceFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data?.contains('20,00') == true &&
          widget.style?.decoration == TextDecoration.lineThrough,
    );
    expect(originalPriceFinder, findsOneWidget);
    final originalPrice = tester.widget<Text>(originalPriceFinder);
    expect(originalPrice.data, contains('20,00'));
    expect(find.textContaining('16,00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
