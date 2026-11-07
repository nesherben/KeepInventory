import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

void main() {
  group('AppNumbers.parseDecimal', () {
    final cases = <String, double?>{
      '12': 12,
      '12,5': 12.5,
      '12.5': 12.5,
      '12,50': 12.5,
      '0,125': 0.125,
      '.5': 0.5,
      ',5': 0.5,
      '12,': 12,
      '1.234,56': 1234.56,
      '1,234.56': 1234.56,
      '1.234.567,8': 1234567.8,
      '1 234,56': 1234.56,
      '1.250': 1250, // un separador + 3 cifras = miles
      '1,250': 1250,
      '1.234.567': 1234567,
      '12 €': 12,
      '€ 8,90': 8.9,
      '-3,5': -3.5,
      '': null,
      'abc': null,
      ',': null,
      '1,2.3,4': null, // separadores mezclados sin sentido
    };
    cases.forEach((input, expected) {
      test('"$input" -> $expected', () {
        final result = AppNumbers.parseDecimal(input);
        if (expected == null) {
          expect(result, isNull);
        } else {
          expect(result, closeTo(expected, 1e-9));
        }
      });
    });

    test('null input', () => expect(AppNumbers.parseDecimal(null), isNull));
  });

  group('AppNumbers.parseInt', () {
    test('accepts thousands separators and integral decimals', () {
      expect(AppNumbers.parseInt('12'), 12);
      expect(AppNumbers.parseInt('1.200'), 1200);
      expect(AppNumbers.parseInt('12,0'), 12);
    });

    test('rejects fractions and garbage', () {
      expect(AppNumbers.parseInt('12,5'), isNull);
      expect(AppNumbers.parseInt('x'), isNull);
    });
  });

  group('AppNumbers formatting', () {
    test('Spanish uses comma decimals and dot thousands', () {
      expect(AppNumbers.money(1234.5, locale: 'es'), '1.234,50 €');
      expect(AppNumbers.money(8, locale: 'es'), '8,00 €');
      expect(AppNumbers.amount(0.5, locale: 'es'), '0,50');
      expect(AppNumbers.input(1234.5, locale: 'es'), '1234,50');
      expect(AppNumbers.percent(12.5, locale: 'es', maxDecimals: 1), '12,5 %');
    });

    test('English uses dot decimals and comma thousands', () {
      expect(AppNumbers.money(1234.5, locale: 'en'), '1,234.50 €');
      expect(AppNumbers.input(1234.5, locale: 'en'), '1234.50');
      expect(AppNumbers.percent(75, locale: 'en'), '75 %');
    });

    test('negative amounts', () {
      expect(AppNumbers.money(-3.2, locale: 'es'), '-3,20 €');
    });

    test('formatted values parse back to the same number', () {
      for (final locale in ['es', 'en']) {
        for (final v in [0.0, 0.5, 8.9, 1234.56, 99999.99]) {
          expect(
            AppNumbers.parseDecimal(AppNumbers.money(v, locale: locale)),
            closeTo(v, 1e-9),
            reason: '$locale $v',
          );
          expect(
            AppNumbers.parseDecimal(AppNumbers.input(v, locale: locale)),
            closeTo(v, 1e-9),
          );
        }
      }
    });
  });
}
