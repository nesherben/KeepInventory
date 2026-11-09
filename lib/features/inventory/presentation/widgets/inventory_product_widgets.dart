import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../promotions/domain/promotion.dart';
import '../../domain/inventory_view.dart';
import '../../domain/product.dart';

/// Campos editables uno a uno desde la lista/tabla.
enum InventoryProductField { name, units, price, cost }

/// Acciones comunes a la tarjeta (móvil) y la tabla (tablet).
class InventoryProductActions {
  const InventoryProductActions({
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onEditImage,
    required this.onEditField,
    required this.onStockChange,
    required this.onEditPromotion,
  });

  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;
  final ValueChanged<Product> onEditImage;
  final void Function(Product product, InventoryProductField field) onEditField;
  final void Function(Product product, int amountChange) onStockChange;
  final ValueChanged<Product> onEditPromotion;
}

/// Menú ⋮ con "Editar todo" y "Eliminar".
class InventoryActionMenu extends StatelessWidget {
  const InventoryActionMenu({
    super.key,
    required this.product,
    required this.actions,
  });

  final Product product;
  final InventoryProductActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
      onSelected: (value) {
        if (value == 'edit') actions.onEditProduct(product);
        if (value == 'delete') actions.onDeleteProduct(product);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(context.l10n.editAll),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: colors.error, size: 20),
              const SizedBox(width: 8),
              Text(context.l10n.delete),
            ],
          ),
        ),
      ],
    );
  }
}

/// Foto del producto (o icono "añadir foto"); tocarla permite cambiarla.
class InventoryProductPhoto extends StatelessWidget {
  const InventoryProductPhoto({
    super.key,
    required this.product,
    required this.onTap,
    this.size = 44,
  });

  final Product product;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget placeholder(IconData icon) =>
        Icon(icon, color: colors.onSurfaceVariant, size: size * 0.45);

    Widget image;
    if (product.imageBytes != null && product.imageBytes!.isNotEmpty) {
      image = Image.memory(product.imageBytes!, fit: BoxFit.cover);
    } else if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      image = Image.file(
        File(product.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            placeholder(Icons.image_not_supported_outlined),
      );
    } else {
      image = placeholder(Icons.add_a_photo_outlined);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: image,
      ),
    );
  }
}

/// Control "− unidades +" con aviso de stock bajo/agotado; tocar el número
/// permite escribir la cantidad exacta.
class InventoryStockStepper extends StatelessWidget {
  const InventoryStockStepper({
    super.key,
    required this.product,
    required this.actions,
  });

  final Product product;
  final InventoryProductActions actions;

  @override
  Widget build(BuildContext context) {
    final level = StockLevel.of(product.units);
    return QuantityStepper(
      label: '${product.units}',
      isEmpty: level == StockLevel.out,
      isLow: level == StockLevel.low,
      onDecrement: product.units > 0
          ? () => actions.onStockChange(product, -1)
          : null,
      onIncrement: () => actions.onStockChange(product, 1),
      onTapLabel: () =>
          actions.onEditField(product, InventoryProductField.units),
    );
  }
}

/// Margen en % (rojo si se vende a pérdidas, "—" si el precio es 0).
class InventoryMarginText extends StatelessWidget {
  const InventoryMarginText(this.product, {super.key, this.style});

  final Product product;
  final TextStyle? style;

  static String format(Product product) {
    final pct = product.marginPercent;
    return pct == null ? '—' : '${pct.toStringAsFixed(0)} %';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final negative = product.marginAmount < 0;
    return Text(
      format(product),
      style: (style ?? const TextStyle()).copyWith(
        color: negative ? colors.error : null,
      ),
    );
  }
}

/// Etiqueta de promoción; tocarla abre el selector de promoción.
class InventoryPromotionChip extends StatelessWidget {
  const InventoryPromotionChip({
    super.key,
    required this.promotion,
    required this.onTap,
  });

  final Promotion? promotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final has = promotion != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: has ? AppColors.warning.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: has
                ? AppColors.warning.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              has ? Icons.local_offer : Icons.add,
              size: 14,
              color: has ? AppColors.warning : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                has ? promotion!.name : context.l10n.noPromotion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: has ? FontWeight.w600 : FontWeight.normal,
                  color: has ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Informativa: el producto forma parte de un combo (se gestiona en
/// Promociones → Combos).
class InventoryComboTag extends StatelessWidget {
  const InventoryComboTag({super.key, required this.comboName});

  final String comboName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.extension, size: 13, color: colors.primary),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            context.l10n.comboCartTitle(comboName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de producto para pantallas estrechas (móvil).
///
/// Tocar la tarjeta = editar todo; foto = cambiar foto; − / + = stock;
/// número = escribir stock; etiqueta = promoción; ⋮ = editar/eliminar.
class InventoryProductCard extends StatelessWidget {
  const InventoryProductCard({
    super.key,
    required this.product,
    required this.promotion,
    required this.actions,
    this.comboName,
  });

  final Product product;
  final Promotion? promotion;
  final InventoryProductActions actions;

  /// Combo al que pertenece (solo informativo).
  final String? comboName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cost = context.money(product.cost);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      onTap: () => actions.onEditProduct(product),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryProductPhoto(
            product: product,
            size: 60,
            onTap: () => actions.onEditImage(product),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      context.money(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        context.l10n.inventoryCostMargin(
                          cost,
                          InventoryMarginText.format(product),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: product.marginAmount < 0
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InventoryStockStepper(product: product, actions: actions),
                    InventoryPromotionChip(
                      promotion: promotion,
                      onTap: () => actions.onEditPromotion(product),
                    ),
                    if (comboName != null)
                      InventoryComboTag(comboName: comboName!),
                  ],
                ),
              ],
            ),
          ),
          InventoryActionMenu(product: product, actions: actions),
        ],
      ),
    );
  }
}
