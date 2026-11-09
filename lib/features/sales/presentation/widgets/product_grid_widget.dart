import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

import 'catalog_tile.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos las Alertas
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
    this.comboProductIds = const {},
    this.missingProductIds = const {},
  });

  /// Productos que forman parte de algún combo (insignia).
  final Set<int> comboProductIds;

  /// Productos que completarían un combo a medias (resaltado).
  final Set<int> missingProductIds;

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
      unitPrice: context.money(product.price),
      stock: product.units,
      cartQty: qtyInCart,

      // Inyectamos los datos de la promoción si existe
      promoName: promo?.name,
      promoActive: promo != null && qtyInCart >= promo.threshold,
      promoThreshold: promo?.threshold,

      actionLabel: qtyInCart > 0
          ? context.l10n.addAnotherUnit
          : context.l10n.addToCart,
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
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final qtyInCart = cart[product] ?? 0;
        return CatalogTile(
          image: buildProductImage(product),
          name: product.name,
          price: product.price,
          stock: product.units,
          quantityInCart: qtyInCart,
          onTap: product.units > 0
              ? () => onAddToCart(product)
              : () => AppAlerts.showError(
                  context,
                  context.l10n.productOutOfStock,
                ),
          onLongPress: () => _showPreview(context, product, qtyInCart),
          onRemove: () => onRemoveFromCart(product),
          onRemoveAll: () => onRemoveAllFromCart(product),
          comboLabel: comboProductIds.contains(product.id)
              ? context.l10n.comboBadge
              : null,
          highlight:
              product.units > 0 && missingProductIds.contains(product.id),
        );
      },
    );
  }
}
