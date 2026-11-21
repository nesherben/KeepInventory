import 'package:flutter/material.dart';

/// Lista de tarjetas que en pantallas anchas (tablet) se reparte en varias
/// columnas en vez de estirar cada tarjeta a todo el ancho. En móvil es una
/// lista normal. Las tarjetas se alinean arriba, cada una con su altura.
class AdaptiveCardList extends StatelessWidget {
  const AdaptiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.minColumnWidth = 480,
    this.maxColumns = 3,
    this.gap = 12,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;

  /// Ancho mínimo de cada columna: define cuántas caben.
  final double minColumnWidth;
  final int maxColumns;

  /// Separación horizontal entre columnas.
  final double gap;

  /// Columnas que caben en [width] (sin contar el relleno).
  static int columnsFor(
    double width, {
    double minColumnWidth = 480,
    double gap = 12,
    int maxColumns = 3,
  }) {
    final fit = ((width + gap) / (minColumnWidth + gap)).floor();
    return fit.clamp(1, maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(
          constraints.maxWidth - padding.horizontal,
          minColumnWidth: minColumnWidth,
          gap: gap,
          maxColumns: maxColumns,
        );
        if (columns == 1) {
          return ListView.builder(
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
        final rows = (itemCount / columns).ceil();
        return ListView.builder(
          padding: padding,
          itemCount: rows,
          itemBuilder: (context, row) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: gap),
                Expanded(
                  child: row * columns + c < itemCount
                      ? itemBuilder(context, row * columns + c)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
