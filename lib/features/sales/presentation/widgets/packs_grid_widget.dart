import 'package:flutter/material.dart';

import '../../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos las alertas
import '../../../../core/shared_widgets/auto_scroll_text.dart';
import '../../../packs/domain/pack.dart';

import 'item_preview.dart';

class PacksGridWidget extends StatelessWidget {
  final List<Pack> packs;
  final Map<Pack, int> cartPacks;
  final double bottomPadding;
  final int crossAxisCount;
  final Function(Pack) onAddToCart;
  final Function(Pack) onRemoveFromCart;
  final Function(Pack) onRemoveAllFromCart;

  const PacksGridWidget({
    super.key,
    required this.packs,
    required this.cartPacks,
    required this.bottomPadding,
    required this.crossAxisCount,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onRemoveAllFromCart,
  });

  /// Mantener pulsada la tarjeta => se amplía con todos los datos.
  void _showPreview(BuildContext context, Pack pack, int qtyInCart) {
    final contents = pack.items.map((item) => item.productName).join(', ');

    showItemPreview(
      context,
      image: buildPackImage(pack),
      title: pack.name,
      unitPrice: '${pack.price.toStringAsFixed(2)} €',
      stock: pack.units,
      cartQty: qtyInCart, // El popup ocultará el chip automáticamente si es 0
      packContents: contents.isNotEmpty ? contents : null,

      // 💡 Configuramos el botón de acción
      actionLabel: qtyInCart > 0 ? 'Añadir otro pack' : 'Añadir al carrito',
      actionIcon: Icons.library_add_outlined,
      onAction: () {
        onAddToCart(pack);
      },
      onRemoveAction: () => onRemoveFromCart(pack),
      onRemoveAllAction: () => onRemoveAllFromCart(pack),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: packs.length,
      itemBuilder: (context, index) {
        final pack = packs[index];
        final hasStock = pack.units > 0;
        final qtyInCart = cartPacks[pack] ?? 0;
        final isInCart = qtyInCart > 0;

        Widget cardContent = Card(
          elevation: isInCart ? 6 : 2,
          // 💡 Fondo suave para la tarjeta si está seleccionada (adaptativo)
          color: isInCart
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              // 💡 Borde adaptado al color scheme
              color: isInCart
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: isInCart ? 3.0 : 0.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: buildPackImage(pack)),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  children: [
                    // Si el nombre no cabe, hace scroll automático
                    AutoScrollText(
                      pack.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${pack.price.toStringAsFixed(2)} €',
                      style: TextStyle(
                        // 💡 Precio adaptado al color scheme
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (!hasStock) {
          return GestureDetector(
            onTap: () {
              // 💡 ¡Mucho más limpio usando AppAlerts!
              AppAlerts.showError(context, 'Este pack no tiene stock montado.');
            },
            onLongPress: () => _showPreview(context, pack, qtyInCart),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: Opacity(opacity: 0.6, child: cardContent),
            ),
          );
        }

        return InkWell(
          onTap: () => onAddToCart(pack),
          onLongPress: () => _showPreview(context, pack, qtyInCart),
          child: Stack(
            children: [
              Positioned.fill(child: cardContent),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${pack.units}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              if (isInCart)
                Positioned(
                  top: 4,
                  left: 4,
                  child: CircleAvatar(
                    radius: 13,
                    // 💡 Avatar dinámico
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      '$qtyInCart',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isInCart)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Material(
                    // 💡 Botón de restar rojo dinámico
                    color: Theme.of(context).colorScheme.error,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemoveFromCart(pack),
                      onLongPress: () => onRemoveAllFromCart(pack),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
