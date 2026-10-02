import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/promotions/domain/fixed_price_bundle_calculator.dart';

void main() {
  test('discounts complete bundles against the highest-priced units first', () {
    final totals = FixedPriceBundleCalculator.calculateItemTotals(
      quantities: {'expensive': 2, 'cheap': 1},
      priceOf: (item) => item == 'expensive' ? 10 : 5,
      bundleSize: 2,
      bundlePrice: 12,
    );

    expect(totals, {'expensive': 12, 'cheap': 5});
  });

  test('rejects a non-positive bundle size', () {
    expect(
      () => FixedPriceBundleCalculator.calculateItemTotals(
        quantities: {'product': 1},
        priceOf: (_) => 5,
        bundleSize: 0,
        bundlePrice: 12,
      ),
      throwsArgumentError,
    );
  });
}
