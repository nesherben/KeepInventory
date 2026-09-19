import 'package:flutter/material.dart';

import '../../../../core/shared_widgets/auto_scroll_text.dart';
import '../../../inventory/domain/product.dart';
import '../../../packs/domain/pack.dart';
import '../../../promotions/domain/promotion.dart';

import 'sales_ui_utils.dart';

class CartItemsListWidget extends StatelessWidget {
  final Map<Product, int> cart;
  final Map<Pack, int> cartPacks;
  final Map<int, Promotion> promotionsMap;

  final double Function(Product, Map<Product, int>, Map<int, Promotion>)
  calculateItemTotal;

  final Function(Product) onRemoveFromCart;
  final Function(Product) onRemoveAllFromCart;
  final Function(Pack) onRemovePackFromCart;
  final Function(Pack) onRemoveAllPackFromCart;

  const CartItemsListWidget({
    super.key,
    required this.cart,
    required this.cartPacks,
    required this.promotionsMap,
    required this.calculateItemTotal,
    required this.onRemoveFromCart,
    required this.onRemoveAllFromCart,
    required this.onRemovePackFromCart,
    required this.onRemoveAllPackFromCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cart.isEmpty && cartPacks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_shopping_cart_outlined,
                size: 64,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 16),
              Text(
                'El carrito está vacío',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true, // 💡 LA SOLUCIÓN AL CRASH: Le dice a la lista que no se expanda al infinito
      physics: const ClampingScrollPhysics(), // 💡 Evita que el scroll del carrito pelee con el scroll de la pantalla
      children: [
        // --- PRODUCTOS SUELTOS (Con lógica Mix & Match) ---
        ...cart.keys.map((product) {
          final qty = cart[product]!;
          final itemTotal = calculateItemTotal(product, cart, promotionsMap);
          final Promotion? promo = promotionsMap[product.promotionId];

          int otherItemsInPromo = 0;
          if (promo != null) {
            otherItemsInPromo = cart.keys
                .where((p) => p.promotionId == promo.id && p.id != product.id)
                .fold(0, (sum, p) => sum + cart[p]!);
          }

          final int combinedQty = qty + otherItemsInPromo;
          final bool promoActive =
              promo != null && combinedQty >= promo.threshold;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // IMAGEN
                    Container(
                      width: 56,
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: buildProductImage(product),
                    ),
                    const SizedBox(width: 12),

                    // TEXTOS Y ETIQUETAS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoScrollText(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${qty}x',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${product.price.toStringAsFixed(2)} €/ud',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (promo != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 12,
                                  color: promoActive
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    promoActive
                                        ? 'Oferta aplicada: ${promo.name}'
                                        : 'Promo disponible: ${promo.name}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: promoActive
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // TOTAL Y BOTÓN DE BORRAR
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${itemTotal.toStringAsFixed(2)} €',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onRemoveFromCart(product),
                            onLongPress: () => onRemoveAllFromCart(product),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // --- PACKS ---
        ...cartPacks.keys.map((pack) {
          final qty = cartPacks[pack]!;
          final itemTotal = pack.price * qty;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onLongPress: () => showCartPackPreview(
                context,
                pack: pack,
                qty: qty,
                itemTotal: itemTotal,
                onAddAction: null,
                onRemoveAction: () => onRemovePackFromCart(pack),
                onRemoveAllAction: () => onRemoveAllPackFromCart(pack),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: buildPackImage(pack),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoScrollText(
                            pack.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${qty}x',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${pack.price.toStringAsFixed(2)} €/pack',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PACK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${itemTotal.toStringAsFixed(2)} €',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onRemovePackFromCart(pack),
                            onLongPress: () => onRemoveAllPackFromCart(pack),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
