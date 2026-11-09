import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

import 'catalog_tile.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos las Alertas
import '../../../inventory/domain/product.dart';

import '../../../promotions/domain/promotion.dart';
import '../../../promotions/data/datasources/promotion_local_datasource.dart';
import 'sales_ui_utils.dart';

class ProductGridWidget extends StatefulWidget {
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
    this.focusedProductId,
    this.focusRequest = 0,
  });

  /// Productos que forman parte de algún combo (insignia).
  final Set<int> comboProductIds;

  /// Productos que completarían un combo a medias (resaltado).
  final Set<int> missingProductIds;

  /// Producto al que llevar (scroll + resaltado), p. ej. desde el aviso de
  /// combo del carrito. Cada nueva petición incrementa [focusRequest].
  final int? focusedProductId;
  final int focusRequest;

  @override
  State<ProductGridWidget> createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<ProductGridWidget> {
  final _scrollController = ScrollController();
  static const _padding = 12.0;
  static const _spacing = 10.0;
  static const _aspectRatio = 0.72;
  double _width = 0;

  List<Product> get products => widget.products;
  Map<Product, int> get cart => widget.cart;
  double get bottomPadding => widget.bottomPadding;
  int get crossAxisCount => widget.crossAxisCount;
  Function(Product) get onAddToCart => widget.onAddToCart;
  Function(Product) get onRemoveFromCart => widget.onRemoveFromCart;
  Function(Product) get onRemoveAllFromCart => widget.onRemoveAllFromCart;
  Set<int> get comboProductIds => widget.comboProductIds;
  Set<int> get missingProductIds => widget.missingProductIds;

  @override
  void didUpdateWidget(covariant ProductGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusRequest != oldWidget.focusRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocused());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Desplaza la cuadrícula hasta la fila del producto enfocado.
  void _scrollToFocused() {
    final index = products.indexWhere((p) => p.id == widget.focusedProductId);
    if (index < 0 || !_scrollController.hasClients || _width <= 0) return;
    final tileWidth =
        (_width - 2 * _padding - _spacing * (crossAxisCount - 1)) /
        crossAxisCount;
    final rowExtent = tileWidth / _aspectRatio + _spacing;
    final row = index ~/ crossAxisCount;
    final target = (row * rowExtent).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        return _buildGrid(context);
      },
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(_padding, _padding, _padding, bottomPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _aspectRatio,
        crossAxisSpacing: _spacing,
        mainAxisSpacing: _spacing,
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
              product.id == widget.focusedProductId ||
              (product.units > 0 && missingProductIds.contains(product.id)),
        );
      },
    );
  }
}
