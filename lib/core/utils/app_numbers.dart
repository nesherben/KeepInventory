import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Intl, NumberFormat;

/// Formateo y lectura de números/importes de la app.
///
/// - Mostrar: separadores del idioma y "€" detrás (es: "1.234,50 €",
///   en: "1,234.50 €"), igual que en los textos traducidos.
/// - Leer: tolerante con la puntuación que escriba el usuario.
abstract final class AppNumbers {
  static String _locale(String? locale) =>
      Intl.canonicalizedLocale(locale ?? Intl.getCurrentLocale());

  /// "1.234,50" (es) / "1,234.50" (en).
  static String amount(double value, {String? locale}) =>
      NumberFormat('#,##0.00', _locale(locale)).format(value);

  /// "1.234,50 €".
  static String money(double value, {String? locale}) =>
      '${amount(value, locale: locale)} €';

  /// Valor para rellenar un campo editable: sin miles ("1234,50").
  static String input(double value, {String? locale}) =>
      NumberFormat('0.00', _locale(locale)).format(value);

  /// "75 %" / "12,5 %".
  static String percent(double value, {String? locale, int maxDecimals = 0}) {
    final pattern = maxDecimals == 0 ? '0' : '0.${'#' * maxDecimals}';
    return '${NumberFormat(pattern, _locale(locale)).format(value)} %';
  }

  /// Lee un decimal aceptando coma o punto como separador decimal y
  /// separadores de miles: "12,5", "12.5", "1.234,56", "1,234.56", "12 €".
  ///
  /// Regla para un único separador seguido de exactamente 3 cifras
  /// ("1.250"): se interpreta como miles (1250), salvo que la parte entera
  /// sea 0 ("0,125" → 0.125). Devuelve null si no es un número.
  static double? parseDecimal(String? input) {
    if (input == null) return null;
    var s = input.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    final negative = s.startsWith('-');
    s = s.replaceAll('-', '');
    if (s.isEmpty || !s.contains(RegExp(r'[0-9]'))) return null;

    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    String? decimalSep;
    if (lastComma >= 0 && lastDot >= 0) {
      decimalSep = lastComma > lastDot ? ',' : '.';
    } else if (lastComma >= 0 || lastDot >= 0) {
      final sep = lastComma >= 0 ? ',' : '.';
      final occurrences = sep.allMatches(s).length;
      final sepIndex = s.lastIndexOf(sep);
      final digitsAfter = s.length - sepIndex - 1;
      final integerPart = s.substring(0, sepIndex);
      final looksLikeThousands =
          occurrences > 1 ||
          (digitsAfter == 3 && integerPart.isNotEmpty && integerPart != '0');
      decimalSep = looksLikeThousands ? null : sep;
    }

    var integerPart = s;
    var fraction = '';
    if (decimalSep != null) {
      final i = s.lastIndexOf(decimalSep);
      integerPart = s.substring(0, i);
      fraction = s.substring(i + 1);
    }
    // Los separadores de miles van antes del decimal, y el separador decimal
    // no puede usarse también como separador de miles ("1,2.3,4")
    if (fraction.contains(RegExp(r'[,.]'))) return null;
    if (decimalSep != null && integerPart.contains(decimalSep)) return null;
    integerPart = integerPart.replaceAll(RegExp(r'[,.]'), '');

    final value = double.tryParse(
      '${integerPart.isEmpty ? '0' : integerPart}'
      '${fraction.isEmpty ? '' : '.$fraction'}',
    );
    if (value == null) return null;
    return negative ? -value : value;
  }

  /// Lee un entero tolerante ("1.200", "12", "12,0"). Null si tiene decimales.
  static int? parseInt(String? input) {
    final value = parseDecimal(input);
    if (value == null || value != value.roundToDouble()) return null;
    return value.round();
  }

  /// Solo deja escribir cifras y separadores (coma, punto).
  static final List<TextInputFormatter> decimalInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  ];

  static final List<TextInputFormatter> integerInputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  static const TextInputType decimalKeyboard = TextInputType.numberWithOptions(
    decimal: true,
  );
}

/// Atajos con el idioma de la pantalla actual.
extension AppNumbersContext on BuildContext {
  String get _numberLocale => Localizations.localeOf(this).toString();

  /// "1.234,50 €"
  String money(double value) => AppNumbers.money(value, locale: _numberLocale);

  /// "1.234,50" (para textos traducidos que ya llevan "€").
  String amount(double value) =>
      AppNumbers.amount(value, locale: _numberLocale);

  /// "1234,50" para rellenar campos editables.
  String amountInput(double value) =>
      AppNumbers.input(value, locale: _numberLocale);

  String percent(double value, {int maxDecimals = 0}) => AppNumbers.percent(
    value,
    locale: _numberLocale,
    maxDecimals: maxDecimals,
  );
}
