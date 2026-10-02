import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/l10n/app_locale_resolution.dart';
import 'package:keepinventory/l10n/generated/app_localizations.dart';

void main() {
  const supportedLocales = [Locale('es'), Locale('en')];

  test('uses a supported language from the device locale', () {
    expect(
      resolveAppLocale(const Locale('en', 'US'), supportedLocales),
      const Locale('en'),
    );
    expect(
      resolveAppLocale(const Locale('es', 'MX'), supportedLocales),
      const Locale('es'),
    );
  });

  test('falls back to Spanish for unsupported or missing device locales', () {
    expect(
      resolveAppLocale(const Locale('fr'), supportedLocales),
      const Locale('es'),
    );
    expect(resolveAppLocale(null, supportedLocales), const Locale('es'));
  });

  test('loads translated messages from both ARB catalogs', () async {
    final spanish = await AppLocalizations.delegate.load(const Locale('es'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    expect(spanish.salesTitle, 'Panel de Ventas (TPV)');
    expect(english.salesTitle, 'Sales (POS)');
  });
}
