import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/shared_widgets/auto_scroll_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inventory/domain/inventory_view.dart';

/// Ficha del catálogo del TPV (productos y packs).
///
/// Toque = añadir al carrito; pulsación larga = vista previa. Cuando está en
/// el carrito muestra borde primario, contador y botón de quitar (pulsación
/// larga en él = quitar todas las unidades).
class CatalogTile extends StatelessWidget {
  const CatalogTile({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.stock,
    required this.quantityInCart,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    required this.onRemoveAll,
    this.comboLabel,
    this.highlight = false,
  });

  final Widget image;
  final String name;
  final double price;
  final int stock;
  final int quantityInCart;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final VoidCallback onRemoveAll;

  /// Si forma parte de un combo, etiqueta de la insignia ("Combo").
  final String? comboLabel;

  /// Resaltado: completa un combo que ya está a medias en el carrito.
  final bool highlight;

  bool get _inCart => quantityInCart > 0;
  bool get _outOfStock => stock <= 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final tile = Material(
      color: _inCart
          ? Color.alphaBlend(
              colors.primary.withValues(alpha: 0.08),
              theme.cardColor,
            )
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: _inCart
              ? colors.primary
              : highlight
              ? colors.tertiary
              : theme.dividerColor,
          width: _inCart || highlight ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildImage(context)),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 2, 0),
                child: AutoScrollText(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                height: 34,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.money(price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (_inCart) _buildRemoveButton(colors),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!_outOfStock) return tile;

    // Agotado: en gris y atenuado (sigue permitiendo la vista previa)
    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: tile,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lowStock = StockLevel.of(stock) == StockLevel.low;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: colors.surfaceContainerHighest, child: image),
          // Stock disponible
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: lowStock
                    ? AppColors.warning
                    : colors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 11,
                    color: lowStock ? Colors.black87 : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: lowStock ? Colors.black87 : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Forma parte de un combo (icono + texto, no solo color)
          if (comboLabel != null)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.extension, size: 11, color: colors.tertiary),
                    const SizedBox(width: 3),
                    Text(
                      comboLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Unidades en el carrito
          if (_inCart)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 26),
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: Text(
                  '$quantityInCart',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(ColorScheme colors) {
    return Material(
      color: colors.errorContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onRemove,
        onLongPress: onRemoveAll,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.remove, size: 18, color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
