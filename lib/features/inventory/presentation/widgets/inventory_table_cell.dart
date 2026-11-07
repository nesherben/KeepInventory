import 'package:flutter/material.dart';

/// Celda de texto editable de la tabla de inventario: sin recuadro (más
/// limpia de leer); al tocarla muestra el efecto y abre la edición.
class InventoryTableCell extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool bold;
  final Color? textColor;
  final int maxLength;

  const InventoryTableCell({
    super.key,
    required this.text,
    required this.onTap,
    this.bold = false,
    this.textColor,
    this.maxLength = 20,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = text.length > maxLength
        ? '${text.substring(0, maxLength - 3)}...'
        : text;

    return Tooltip(
      message: text.length > maxLength ? text : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            displayText,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
