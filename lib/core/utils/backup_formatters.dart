import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Fecha y hora de una copia ("13/11/2026 00:02"). Siempre día/mes/año, como
/// los tickets del historial, para que la app no mezcle formatos por idioma.
String formatBackupDate(BuildContext context, DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date);

/// Tamaño legible de un archivo ("1,8 MB").
String formatBackupSize(BuildContext context, int bytes) {
  final locale = Localizations.localeOf(context).toString();
  final number = NumberFormat('0.0', locale);
  if (bytes < 1024 * 1024) return '${number.format(bytes / 1024)} KB';
  return '${number.format(bytes / (1024 * 1024))} MB';
}
