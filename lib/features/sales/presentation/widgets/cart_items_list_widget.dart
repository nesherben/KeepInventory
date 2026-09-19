import 'package:flutter/material.dart';

import '../../../../core/shared_widgets/auto_scroll_text.dart';
import '../../../inventory/domain/product.dart';
import '../../../packs/domain/pack.dart';
import '../../../promotions/domain/promotion.dart';

import 'item_preview.dart';

class CartItemsListWidget extends StatelessWidget {
  final Map<Product, int> cart;
  final Map<Pack, int> cartPacks;
  final Map<int, Promotion> promotionsMap;
  final Function(Product, int) calculateItemTotal;
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
    if (cart.isEmpty && cartPacks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48.0),
        child: Center(
          child: Text(
            'El carrito está vacío',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    return ListView(
      children: [
        // Productos individuales
        ...cart.keys.map((product) {
          final qty = cart[product]!;
          final itemTotal = calculateItemTotal(product, qty);

          final Promotion? promo = promotionsMap[product.promotionId];
          final bool promoActive = isPromoActive(promo, qty);

          return ListTile(
            // Mantener pulsado => tarjeta ampliada con todos los datos
            onLongPress: () => showCartProductPreview(
              context,
              product: product,
              qty: qty,
              itemTotal: itemTotal,
              promo: promo,
            ),
            // Si el nombre no cabe, hace scroll automático
            title: AutoScrollText(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${product.price.toStringAsFixed(2)} € x $qty uds'),
                if (promo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    promoActive
                        ? 'Oferta: ${promo.name}'
                        : 'Disponible: ${promo.name}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: promoActive ? Colors.amber.shade800 : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            isThreeLine: promo != null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${itemTotal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  onPressed: () => onRemoveFromCart(product),
                  onLongPress: () => onRemoveAllFromCart(product),
                ),
              ],
            ),
          );
        }),

        // Packs
        ...cartPacks.keys.map((pack) {
          final qty = cartPacks[pack]!;
          final itemTotal = pack.price * qty;

          return ListTile(
            onLongPress: () => showCartPackPreview(
              context,
              pack: pack,
              qty: qty,
              itemTotal: itemTotal,
            ),
            title: AutoScrollText(
              pack.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${pack.price.toStringAsFixed(2)} € x $qty uds (Pack)',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${itemTotal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  onPressed: () => onRemovePackFromCart(pack),
                  onLongPress: () => onRemoveAllPackFromCart(pack),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
