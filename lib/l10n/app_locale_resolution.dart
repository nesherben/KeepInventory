import 'package:flutter/widgets.dart';

/// Idioma por defecto cuando el del dispositivo no está traducido.
const fallbackAppLocale = Locale('en');

/// Elige el idioma de la app según el del dispositivo; si no está
/// soportado, inglés.
Locale resolveAppLocale(
  Locale? deviceLocale,
  Iterable<Locale> supportedLocales,
) {
  if (deviceLocale != null) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == deviceLocale.languageCode) {
        return supportedLocale;
      }
    }
  }
  return fallbackAppLocale;
}

/// Igual que [resolveAppLocale] pero con la lista de idiomas preferidos del
/// dispositivo (p. ej. francés y luego español => español).
Locale resolveAppLocaleList(
  List<Locale>? deviceLocales,
  Iterable<Locale> supportedLocales,
) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
  }
  return fallbackAppLocale;
}
