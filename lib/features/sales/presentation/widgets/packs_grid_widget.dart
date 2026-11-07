import 'package:flutter/material.dart';

import 'catalog_tile.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos las alertas
import '../../../packs/domain/pack.dart';

import 'sales_ui_utils.dart';

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
    final contents = pack.items
        .map((item) => item.productName ?? context.l10n.unknownDeleted)
        .join(', ');

    showItemPreview(
      context,
      image: buildPackImage(pack),
      title: pack.name,
      unitPrice: '${pack.price.toStringAsFixed(2)} €',
      stock: pack.units,
      cartQty: qtyInCart, // El popup ocultará el chip automáticamente si es 0
      packContents: contents.isNotEmpty ? contents : null,

      // 💡 Configuramos el botón de acción
      actionLabel: qtyInCart > 0
          ? context.l10n.addAnotherPack
          : context.l10n.addToCart,
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
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: packs.length,
      itemBuilder: (context, index) {
        final pack = packs[index];
        final qtyInCart = cartPacks[pack] ?? 0;
        return CatalogTile(
          image: buildPackImage(pack),
          name: pack.name,
          price: pack.price,
          stock: pack.units,
          quantityInCart: qtyInCart,
          onTap: pack.units > 0
              ? () => onAddToCart(pack)
              : () => AppAlerts.showError(context, context.l10n.packOutOfStock),
          onLongPress: () => _showPreview(context, pack, qtyInCart),
          onRemove: () => onRemoveFromCart(pack),
          onRemoveAll: () => onRemoveAllFromCart(pack),
        );
      },
    );
  }
}
