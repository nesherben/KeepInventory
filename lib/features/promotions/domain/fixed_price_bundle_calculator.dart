class FixedPriceBundleCalculator {
  const FixedPriceBundleCalculator._();

  static Map<T, double> calculateItemTotals<T>({
    required Map<T, int> quantities,
    required double Function(T item) priceOf,
    required int bundleSize,
    required double bundlePrice,
  }) {
    if (bundleSize <= 0) {
      throw ArgumentError.value(bundleSize, 'bundleSize', 'Must be positive');
    }

    final units = <T>[];
    for (final entry in quantities.entries) {
      for (var i = 0; i < entry.value; i++) {
        units.add(entry.key);
      }
    }
    units.sort((a, b) => priceOf(b).compareTo(priceOf(a)));

    final discountedUnitCount = (units.length ~/ bundleSize) * bundleSize;
    final bundleUnitPrice = bundlePrice / bundleSize;
    final totals = {for (final item in quantities.keys) item: 0.0};

    for (var index = 0; index < units.length; index++) {
      final item = units[index];
      var unitPrice = priceOf(item);
      if (index < discountedUnitCount) {
        // Un lote solo se aplica si sale más barato que sus unidades sueltas:
        // una oferta nunca encarece la compra
        final start = index - index % bundleSize;
        final chunkPrice = units
            .sublist(start, start + bundleSize)
            .fold<double>(0, (t, u) => t + priceOf(u));
        if (bundlePrice < chunkPrice) unitPrice = bundleUnitPrice;
      }
      totals[item] = totals[item]! + unitPrice;
    }

    return totals;
  }
}
