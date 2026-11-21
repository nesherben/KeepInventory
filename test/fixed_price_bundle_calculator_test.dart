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

  group('uncoveredUnits', () {
    test('returns the units that do not complete a bundle', () {
      expect(
        FixedPriceBundleCalculator.uncoveredUnits(
          quantities: {'a': 4},
          priceOf: (_) => 10,
          bundleSize: 3,
        ),
        {'a': 1},
      );
      expect(
        FixedPriceBundleCalculator.uncoveredUnits(
          quantities: {'a': 6},
          priceOf: (_) => 10,
          bundleSize: 3,
        ),
        {'a': 0},
      );
    });

    test('below one bundle every unit is outside', () {
      expect(
        FixedPriceBundleCalculator.uncoveredUnits(
          quantities: {'a': 2},
          priceOf: (_) => 10,
          bundleSize: 3,
        ),
        {'a': 2},
      );
    });

    test(
      'bundles take the most expensive units, so the cheap ones stay out',
      () {
        final result = FixedPriceBundleCalculator.uncoveredUnits(
          quantities: {'expensive': 2, 'cheap': 2},
          priceOf: (item) => item == 'expensive' ? 10 : 5,
          bundleSize: 3,
        );

        expect(result, {'expensive': 0, 'cheap': 1});
      },
    );

    test('agrees with calculateItemTotals about what is covered', () {
      // 2 caras + 2 baratas, lote de 3 por 15: cubre 10+10+5 y deja 1 barata
      final totals = FixedPriceBundleCalculator.calculateItemTotals(
        quantities: {'expensive': 2, 'cheap': 2},
        priceOf: (item) => item == 'expensive' ? 10 : 5,
        bundleSize: 3,
        bundlePrice: 15,
      );

      expect(totals, {'expensive': 10, 'cheap': 10});
    });

    test('rejects a non-positive bundle size', () {
      expect(
        () => FixedPriceBundleCalculator.uncoveredUnits(
          quantities: {'a': 1},
          priceOf: (_) => 5,
          bundleSize: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
