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
  });

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
        // --- COMBOS APLICADOS Y A MEDIAS ---
        for (final application in pricing.combos.applications)
          _ComboSummary(application: application),
        for (final hint in pricing.combos.hints) _ComboHintCard(hint: hint),

        // --- PRODUCTOS SUELTOS (con lógica Mix & Match) ---
        ...cart.keys.map((product) {
          final qty = cart[product]!;
          final itemTotal = pricing.totalOf(product);
          final comboUnits = pricing.comboUnitsOf(product);
          final Promotion? promo = promotionsMap[product.promotionId];

          // Las unidades en combo no cuentan para la promoción propia
          final looseQty = pricing.loose[product] ?? 0;
          int otherItemsInPromo = 0;
          if (promo != null) {
            otherItemsInPromo = pricing.loose.keys
                .where((p) => p.promotionId == promo.id && p.id != product.id)
                .fold(0, (sum, p) => sum + pricing.loose[p]!);
          }
          final promoActive =
              promo != null &&
              looseQty > 0 &&
              looseQty + otherItemsInPromo >= promo.threshold;

          return _CartLine(
            image: buildProductImage(product),
            name: product.name,
            quantity: qty,
            unitPriceLabel: context.l10n.pricePerUnit(
              context.amount(product.price),
            ),
            total: itemTotal,
            extra: comboUnits > 0 && promo != null && looseQty > 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ComboTag(
                        label: context.l10n.comboCartTitle(
                          pricing.combos.applications
                              .where((a) => a.usedUnits.containsKey(product.id))
                              .map((a) => a.combo.name)
                              .join(', '),
                        ),
                      ),
                      _PromoTag(
                        label: promoActive
                            ? context.l10n.promoAppliedName(promo.name)
                            : context.l10n.promoAvailableName(promo.name),
                        active: promoActive,
                      ),
                    ],
                  )
                : comboUnits > 0
                ? _ComboTag(
                    label: context.l10n.comboCartTitle(
                      pricing.combos.applications
                          .where((a) => a.usedUnits.containsKey(product.id))
                          .map((a) => a.combo.name)
                          .join(', '),
                    ),
                  )
                : promo == null
                ? null
                : _PromoTag(
                    label: promoActive
                        ? context.l10n.promoAppliedName(promo.name)
                        : context.l10n.promoAvailableName(promo.name),
                    active: promoActive,
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

class _ComboTag extends StatelessWidget {
  const _ComboTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.extension, size: 12, color: colors.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Combo completo en el carrito: nombre, veces, precio y ahorro.
class _ComboSummary extends StatelessWidget {
  const _ComboSummary({required this.application});

  final ComboApplication application;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final saving = application.saving;
    final title = context.l10n.comboCartTitle(application.combo.name);
    return Semantics(
      container: true,
      label: '$title, ${context.money(application.total)}',
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: colors.primary,
        child: Row(
          children: [
            const IconBadge(Icons.extension),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.count > 1
                        ? '$title ${context.l10n.comboCount(application.count)}'
                        : title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (saving > 0.005)
                    Text(
                      context.l10n.comboSaving(context.amount(saving)),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              context.money(application.total),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combo a medias: "Te falta: Ratón". Ayuda a sugerir la venta.
class _ComboHintCard extends StatelessWidget {
  const _ComboHintCard({required this.hint});

  final ComboHint hint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final missing = hint.missing
        .map((s) => s.quantity > 1 ? '${s.quantity} × ${s.name}' : s.name)
        .join(', ');
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${context.l10n.comboCartTitle(hint.combo.name)} · '
                '${context.l10n.comboMissingHint(missing)}',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
