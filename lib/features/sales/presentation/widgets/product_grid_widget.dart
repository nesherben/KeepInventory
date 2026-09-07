import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos las Alertas
import '../../../inventory/domain/product.dart';

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
              Expanded(
                child: product.imageBytes != null
                    ? Image.memory(
                        product.imageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surfaceMuted,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textSubtle,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : (product.imagePath != null
                          ? Image.file(
                              File(product.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.surfaceMuted,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppColors.textSubtle,
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.surfaceMuted,
                              child: const Icon(
                                Icons.inventory,
                                color: AppColors.textSubtle,
                                size: 40,
                              ),
                            )),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
