import 'package:flutter/material.dart';

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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 15 : 14,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
