import 'package:flutter/material.dart';

import '../../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos las Alertas
import '../../../../core/shared_widgets/auto_scroll_text.dart';
import '../../../inventory/domain/product.dart';

import '../../../promotions/domain/promotion.dart';
import '../../../promotions/data/datasources/promotion_local_datasource.dart';
import 'sales_ui_utils.dart';

class ProductGridWidget extends StatelessWidget {
  final List<Product> products;
  final Map<Product, int> cart;
  final double bottomPadding;
  final int crossAxisCount;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final Function(Product) onRemoveAllFromCart;

  const ProductGridWidget({
    super.key,
    required this.products,
    required this.cart,
    required this.bottomPadding,
    required this.crossAxisCount,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onRemoveAllFromCart,
  });

  /// Mantener pulsada la tarjeta => se amplía con todos los datos.
  Future<void> _showPreview(
    BuildContext context,
    Product product,
    int qtyInCart,
  ) async {
    Promotion? promo;
    if (product.promotionId != null) {
      final promoDataSource = PromotionLocalDatasource();
      final allPromotions = await promoDataSource.getPromotions();

      // 💡 Forma súper limpia (Dart 3.0+)
      promo = allPromotions
          .where((p) => p.id == product.promotionId)
          .firstOrNull;
    }

    // 2. Verificamos que el usuario no haya cerrado la pantalla mientras cargaba
    if (!context.mounted) return;

    // 3. Lanzamos nuestro popup rediseñado (sin auto-cierre y con feedback)
    showItemPreview(
      context,
      image: buildProductImage(product),
      title: product.name,
      unitPrice: '${product.price.toStringAsFixed(2)} €',
      stock: product.units,
      cartQty: qtyInCart,

      // Inyectamos los datos de la promoción si existe
      promoName: promo?.name,
      promoActive: promo != null && qtyInCart >= promo.threshold,
      promoThreshold: promo?.threshold,

      actionLabel: qtyInCart > 0 ? 'Añadir otra unidad' : 'Añadir al carrito',
      actionIcon: Icons.add_shopping_cart,
      onAction: () {
        onAddToCart(product);
      },
      onRemoveAction: () => onRemoveFromCart(product),
      onRemoveAllAction: () => onRemoveAllFromCart(product),
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
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final hasStock = product.units > 0;
        final qtyInCart = cart[product] ?? 0;
        final isInCart = qtyInCart > 0;

        Widget cardContent = Card(
          elevation: isInCart ? 6 : 2,
          // 💡 Fondo suave para la tarjeta si está seleccionada
          color: isInCart
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              // 💡 Usamos colorScheme.primary para el modo oscuro
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
              Expanded(child: buildProductImage(product)),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  children: [
                    // Si el nombre no cabe, hace scroll automático
                    AutoScrollText(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${product.price.toStringAsFixed(2)} €',
                      style: TextStyle(
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
              AppAlerts.showError(context, 'Este producto está sin stock.');
            },
            onLongPress: () => _showPreview(context, product, qtyInCart),
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
          onTap: () => onAddToCart(product),
          onLongPress: () => _showPreview(context, product, qtyInCart),
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
                    '${product.units}',
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
                    color: Theme.of(context).colorScheme.error,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemoveFromCart(product),
                      onLongPress: () => onRemoveAllFromCart(product),
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
