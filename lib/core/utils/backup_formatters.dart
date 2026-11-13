import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Fecha y hora de una copia, en el idioma de la app ("13/11/2026 00:02").
String formatBackupDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(date);
}

/// Tamaño legible de un archivo ("1,8 MB").
String formatBackupSize(BuildContext context, int bytes) {
  final locale = Localizations.localeOf(context).toString();
  final number = NumberFormat('0.0', locale);
  if (bytes < 1024 * 1024) return '${number.format(bytes / 1024)} KB';
  return '${number.format(bytes / (1024 * 1024))} MB';
}
