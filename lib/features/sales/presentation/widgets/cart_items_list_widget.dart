import '../../../inventory/domain/inventory_view.dart';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/app_ui.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/auto_scroll_text.dart';
import '../../../inventory/domain/product.dart';
import '../../../packs/domain/pack.dart';
import '../../../promotions/domain/combo_matcher.dart';
import '../../../promotions/domain/promotion.dart';
import '../../domain/sale_cart_pricing_calculator.dart';

import 'sales_ui_utils.dart';

class CartItemsListWidget extends StatelessWidget {
  final Map<Product, int> cart;
  final Map<Pack, int> cartPacks;
  final Map<int, Promotion> promotionsMap;

  /// Precio ya calculado del carrito (combos + promociones).
  final CartPricing pricing;

  final Function(Product) onRemoveFromCart;
  final Function(Product) onRemoveAllFromCart;
  final Function(Pack) onRemovePackFromCart;
  final Function(Pack) onRemoveAllPackFromCart;

  /// Catálogo y acción de añadir: para el botón "Añadir" de un combo a medias.
  final List<Product> catalog;
  final Function(Product)? onAddToCart;

  /// Tocar el aviso de combo a medias: lleva al producto en el catálogo.
  final Function(Product)? onLocateProduct;

  const CartItemsListWidget({
    super.key,
    required this.cart,
    required this.cartPacks,
    required this.promotionsMap,
    required this.pricing,
    required this.onRemoveFromCart,
    required this.onRemoveAllFromCart,
    required this.onRemovePackFromCart,
    required this.onRemoveAllPackFromCart,
    this.catalog = const [],
    this.onAddToCart,
    this.onLocateProduct,
  });

  /// Añade al carrito lo que falta para completar el combo (null si no hay
  /// stock o no se puede añadir).
  VoidCallback? _completeComboAction(ComboHint hint) {
    final add = onAddToCart;
    if (add == null) return null;
    final byId = {for (final p in catalog) p.id: p};
    final toAdd = <Product>[];
    for (final slot in hint.missing) {
      final have = slot.productIds.fold<int>(
        0,
        (t, id) => t + (pricing.combos.remaining[id] ?? 0),
      );
      var need = slot.quantity - have;
      for (final id in slot.productIds) {
        final product = byId[id];
        if (product == null) continue;
        // Stock libre = unidades - las que ya están en el carrito
        var free = product.units - (cart[product] ?? 0);
        while (need > 0 && free > 0) {
          toAdd.add(product);
          need--;
          free--;
        }
        if (need == 0) break;
      }
      if (need > 0) return null; // no hay stock suficiente
    }
    if (toAdd.isEmpty) return null;
    return () {
      for (final product in toAdd) {
        add(product);
      }
    };
  }

  Product? _firstMissingProduct(ComboHint hint) {
    final byId = {for (final p in catalog) p.id: p};
    Product? fallback;
    for (final slot in hint.missing) {
      for (final id in slot.productIds) {
        final product = byId[id];
        if (product == null) continue;
        fallback ??= product;
        if (product.units > (cart[product] ?? 0)) return product;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty && cartPacks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyState(
          icon: Icons.remove_shopping_cart_outlined,
          title: context.l10n.cartEmpty,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true, // 💡 Evita el crash: la lista no se expande al infinito
      physics: const ClampingScrollPhysics(), // 💡 No pelea con el scroll de la pantalla
      children: [
        // --- COMBOS: cada uno agrupa sus productos en líneas pequeñas ---
        for (final application in pricing.combos.applications)
          _ComboGroup(
            application: application,
            products: {
              for (final p in cart.keys)
                if (application.usedUnits.containsKey(p.id)) p.id!: p,
            },
            cartQuantities: {
              for (final e in cart.entries)
                if (e.key.id != null) e.key.id!: e.value,
            },
            onRemove: onRemoveFromCart,
          ),
        for (final hint in pricing.combos.hints)
          _ComboHintCard(
            hint: hint,
            onAdd: _completeComboAction(hint),
            onTap: () {
              final product = _firstMissingProduct(hint);
              if (product != null) onLocateProduct?.call(product);
            },
          ),

        // --- PRODUCTOS SUELTOS (las unidades que no van en combo) ---
        ...pricing.loose.keys.map((product) {
          final qty = pricing.loose[product]!;
          // Total de las sueltas = total del producto - su parte de combo
          final comboShare = pricing.combos.applications.fold<double>(
            0,
            (t, a) => t + (a.lineTotals[product.id] ?? 0),
          );
          final itemTotal = pricing.totalOf(product) - comboShare;
          final Promotion? promo = promotionsMap[product.promotionId];

          // Las unidades en combo no cuentan para la promoción propia
          int otherItemsInPromo = 0;
          if (promo != null) {
            otherItemsInPromo = pricing.loose.keys
                .where((p) => p.promotionId == promo.id && p.id != product.id)
                .fold(0, (sum, p) => sum + pricing.loose[p]!);
          }
          final promoActive =
              promo != null && qty + otherItemsInPromo >= promo.threshold;

          return _CartLine(
            image: buildProductImage(product),
            name: product.name,
            quantity: qty,
            unitPriceLabel: context.l10n.pricePerUnit(
              context.amount(product.price),
            ),
            total: itemTotal,
            extra: _lineExtras(
              context,
              promo: promo == null
                  ? null
                  : _PromoTag(
                      label: promoActive
                          ? context.l10n.promoAppliedName(promo.name)
                          : context.l10n.promoAvailableName(promo.name),
                      active: promoActive,
                    ),
              stock: _StockLeftTag.forProduct(product, cart[product] ?? 0),
            ),
            onRemove: () => onRemoveFromCart(product),
            onRemoveAll: () => onRemoveAllFromCart(product),
            onLongPress: () => showCartProductPreview(
              context,
              product: product,
              qty: qty,
              itemTotal: itemTotal,
              promo: promo,
              otherItemsInPromo: otherItemsInPromo,
              onAddAction: null,
              onRemoveAction: () => onRemoveFromCart(product),
              onRemoveAllAction: () => onRemoveAllFromCart(product),
            ),
          );
        }),

        // --- PACKS ---
        ...cartPacks.keys.map((pack) {
          final qty = cartPacks[pack]!;
          final itemTotal = pack.price * qty;

          return _CartLine(
            image: buildPackImage(pack),
            name: pack.name,
            quantity: qty,
            unitPriceLabel: context.l10n.pricePerPack(
              context.amount(pack.price),
            ),
            total: itemTotal,
            extra: const _PackTag(),
            onRemove: () => onRemovePackFromCart(pack),
            onRemoveAll: () => onRemoveAllPackFromCart(pack),
            onLongPress: () => showCartPackPreview(
              context,
              pack: pack,
              qty: qty,
              itemTotal: itemTotal,
              onAddAction: null,
              onRemoveAction: () => onRemovePackFromCart(pack),
              onRemoveAllAction: () => onRemoveAllPackFromCart(pack),
            ),
          );
        }),
      ],
    );
  }
}

/// Línea del carrito: imagen · nombre, cantidad y precio unitario · total y
/// botón de quitar (pulsación larga = quitar todas).
class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.image,
    required this.name,
    required this.quantity,
    required this.unitPriceLabel,
    required this.total,
    required this.onRemove,
    required this.onRemoveAll,
    required this.onLongPress,
    this.extra,
  });

  final Widget image;
  final String name;
  final int quantity;
  final String unitPriceLabel;
  final double total;
  final Widget? extra;
  final VoidCallback onRemove;
  final VoidCallback onRemoveAll;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      onLongPress: onLongPress,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: image,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoScrollText(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${quantity}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        unitPriceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (extra != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  extra!,
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.money(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onRemove,
                  onLongPress: onRemoveAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 18,
                      color: colors.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Promoción del producto: verde si se aplica, gris si aún no.
class _PromoTag extends StatelessWidget {
  const _PromoTag({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.success
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.local_offer, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PackTag extends StatelessWidget {
  const _PackTag();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.card_giftcard, size: 12, color: colors.secondary),
        const SizedBox(width: 4),
        Text(
          'PACK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Combo en el carrito: cabecera (nombre ×veces, ahorro y precio) y debajo
/// sus productos en líneas pequeñas, todo dentro de un mismo recuadro.
class _ComboGroup extends StatelessWidget {
  const _ComboGroup({
    required this.application,
    required this.products,
    required this.onRemove,
    this.cartQuantities = const {},
  });

  final ComboApplication application;
  final Map<int, Product> products;

  /// Unidades de cada producto en todo el carrito (para el aviso de stock).
  final Map<int, int> cartQuantities;
  final Function(Product) onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final saving = application.saving;
    final name = application.count > 1
        ? '${application.combo.name} ${context.l10n.comboCount(application.count)}'
        : application.combo.name;
    return Semantics(
      container: true,
      label:
          '${context.l10n.comboCartTitle(name)}, ${context.money(application.total)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.primary.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.extension, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (saving > 0.005) ...[
                  Text(
                    '−${context.money(saving)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(
                    context.money(application.total),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final entry in application.usedUnits.entries)
              if (products[entry.key] != null)
                _ComboItemLine(
                  product: products[entry.key]!,
                  quantity: entry.value,
                  inCart: cartQuantities[entry.key] ?? entry.value,
                  onRemove: () => onRemove(products[entry.key]!),
                ),
          ],
        ),
      ),
    );
  }
}

/// Producto dentro de un combo: miniatura, "1× Nombre" y quitar.
class _ComboItemLine extends StatelessWidget {
  const _ComboItemLine({
    required this.product,
    required this.quantity,
    required this.onRemove,
    this.inCart = 0,
  });

  final Product product;
  final int quantity;
  final VoidCallback onRemove;

  /// Unidades del producto en todo el carrito.
  final int inCart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: buildProductImage(product),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$quantity×',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          ?_StockLeftTag.forProduct(product, inCart),
          IconButton(
            tooltip: context.l10n.delete,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: colors.error,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Combo a medias, en una línea: "Camiseta + gorra · falta Gorra [＋ Añadir]".
class _ComboHintCard extends StatelessWidget {
  const _ComboHintCard({required this.hint, this.onAdd, this.onTap});

  final ComboHint hint;

  /// Tocar el aviso: ir al producto que falta en el catálogo.
  final VoidCallback? onTap;

  /// Añade lo que falta (null = sin stock: no se muestra el botón).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final missing = hint.missing
        .map((s) => s.quantity > 1 ? '${s.quantity} × ${s.name}' : s.name)
        .join(', ');
    return Semantics(
      liveRegion: true,
      button: onTap != null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                onAdd == null ? AppSpacing.sm : 2,
                onAdd == null ? AppSpacing.md : 4,
                onAdd == null ? AppSpacing.sm : 2,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.extension_outlined,
                    size: 18,
                    color: colors.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: hint.combo.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                ' · ${context.l10n.comboMissingShort(missing)}',
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  if (onAdd != null)
                    TextButton.icon(
                      onPressed: onAdd,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.onSecondaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.l10n.comboAddMissing),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiquetas extra de una línea del carrito (promoción y stock), apiladas.
Widget? _lineExtras(BuildContext context, {Widget? promo, Widget? stock}) {
  if (promo == null && stock == null) return null;
  if (promo == null) return stock;
  if (stock == null) return promo;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [promo, const SizedBox(height: 2), stock],
  );
}

/// "Quedan 2 en stock" / "Se agota con esta venta" cuando la venta deja el
/// producto con poco stock (umbral de stock bajo del inventario).
class _StockLeftTag extends StatelessWidget {
  const _StockLeftTag(this.left);

  final int left;

  static _StockLeftTag? forProduct(Product product, int inCart) {
    final left = product.units - inCart;
    return left <= StockLevel.lowThreshold ? _StockLeftTag(left) : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final out = left <= 0;
    final color = out ? colors.error : AppColors.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          out ? context.l10n.cartStockOut : context.l10n.cartStockLeft(left),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: out ? colors.error : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
