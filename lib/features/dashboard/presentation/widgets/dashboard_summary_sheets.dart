import 'package:flutter/material.dart';

import '../../../../core/shared_widgets/app_ui.dart';

/// Ficha (bottom sheet) con la explicación de una cifra del Inicio y,
/// opcionalmente, su detalle y un botón de acceso a la pantalla completa.
void showSummarySheet(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required String value,
  required String info,
  List<Widget> details = const [],
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            info,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...details,
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(sheetContext);
                onAction();
              },
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Fila de detalle de una ficha: texto a la izquierda, valor a la derecha.
Widget summaryDetailRow(
  String left,
  String right, {
  Color? rightColor,
  Widget? leading,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    children: [
      if (leading != null) ...[leading, const SizedBox(width: 10)],
      Expanded(child: Text(left, maxLines: 1, overflow: TextOverflow.ellipsis)),
      Text(
        right,
        style: TextStyle(fontWeight: FontWeight.w700, color: rightColor),
      ),
    ],
  ),
);
