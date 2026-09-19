import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../inventory/domain/product.dart';
import '../../../packs/domain/pack.dart';
import '../../../promotions/domain/promotion.dart';

// ---------------------------------------------------------------------------
// Imágenes
// ---------------------------------------------------------------------------

Widget buildProductImage(Product product, {BoxFit fit = BoxFit.cover}) {
  return _buildImage(
    product.imageBytes,
    product.imagePath,
    Icons.inventory,
    fit,
  );
}

Widget buildPackImage(Pack pack, {BoxFit fit = BoxFit.cover}) {
  return _buildImage(pack.imageBytes, pack.imagePath, Icons.card_giftcard, fit);
}

Widget _placeholder(IconData icon) {
  return Container(
    color: AppColors.surfaceMuted,
    child: Icon(icon, color: AppColors.textSubtle, size: 40),
  );
}

Widget _buildImage(
  Uint8List? bytes,
  String? path,
  IconData fallbackIcon,
  BoxFit fit,
) {
  Widget broken(BuildContext context, Object error, StackTrace? stackTrace) =>
      _placeholder(Icons.image_not_supported_outlined);

  if (bytes != null) {
    return Image.memory(bytes, fit: fit, errorBuilder: broken);
  }
  if (path != null) {
    return Image.file(File(path), fit: fit, errorBuilder: broken);
  }
  return _placeholder(fallbackIcon);
}

// ---------------------------------------------------------------------------
// Promociones
// ---------------------------------------------------------------------------

bool isPromoActive(Promotion? promo, int qty) {
  if (promo == null) return false;
  return (promo.type == 'bundle_fixed_price' || promo.type == 'percentage') &&
      qty >= promo.threshold;
}

// ---------------------------------------------------------------------------
// Vista previa ampliada (REACTIVA Y CON CÁLCULOS REALES)
// ---------------------------------------------------------------------------

class _PreviewInfo extends StatefulWidget {
  final String title;
  final String unitPrice;
  final double? rawPrice;
  final int cartQty;
  final num? cartTotal;
  final int? stock;
  final String? promoName;
  final bool promoActive;
  final int? promoThreshold;
  final String? packContents;

  // 💡 NUEVO: Saber si hay más items combinados en el carrito para esta promo
  final int otherItemsInPromo;

  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  final VoidCallback? onRemoveAction;
  final VoidCallback? onRemoveAllAction;

  const _PreviewInfo({
    required this.title,
    required this.unitPrice,
    this.rawPrice,
    this.cartQty = 0,
    this.otherItemsInPromo = 0, // 💡 INICIALIZADO
    this.cartTotal,
    this.stock,
    this.promoName,
    this.promoActive = false,
    this.promoThreshold,
    this.packContents,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.onRemoveAction,
    this.onRemoveAllAction,
  });

  @override
  State<_PreviewInfo> createState() => _PreviewInfoState();
}

class _PreviewInfoState extends State<_PreviewInfo> {
  bool _justAdded = false;

  late int _localCartQty;
  late int _availableStock;
  late num? _localTotal;
  late bool _localPromoActive;

  @override
  void initState() {
    super.initState();
    _localCartQty = widget.cartQty;

    if (widget.stock != null) {
      _availableStock = widget.stock! - widget.cartQty;
      if (_availableStock < 0) _availableStock = 0;
    } else {
      _availableStock = 9999;
    }

    _localTotal = widget.cartTotal;

    // 💡 EVALUACIÓN INICIAL CON MIX & MATCH
    _localPromoActive = widget.promoThreshold != null
        ? (_localCartQty + widget.otherItemsInPromo) >= widget.promoThreshold!
        : widget.promoActive;
  }

  void _handleTap() async {
    if (widget.onAction == null ||
        (widget.stock != null && _availableStock <= 0)) {
      return;
    }

    widget.onAction!();

    if (mounted) {
      setState(() {
        _justAdded = true;
        _localCartQty++;

        if (widget.stock != null) {
          _availableStock--;
        }

        if (_localTotal != null && widget.rawPrice != null) {
          _localTotal = _localTotal! + widget.rawPrice!;
        }

        // 💡 RE-EVALUAMOS PROMOCIÓN AL AÑADIR (Suma total combinada)
        if (widget.promoThreshold != null &&
            (_localCartQty + widget.otherItemsInPromo) >=
                widget.promoThreshold!) {
          _localPromoActive = true;
        }
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _justAdded = false);
    }
  }

  void _handleRemove() {
    if (widget.onRemoveAction == null || _localCartQty <= 0) return;

    widget.onRemoveAction!();

    if (mounted) {
      setState(() {
        _localCartQty--;
        if (widget.stock != null) _availableStock++;

        if (_localTotal != null && widget.rawPrice != null) {
          _localTotal = _localTotal! - widget.rawPrice!;
        }

        // 💡 RE-EVALUAMOS PROMOCIÓN AL QUITAR
        if (widget.promoThreshold != null &&
            (_localCartQty + widget.otherItemsInPromo) <
                widget.promoThreshold!) {
          _localPromoActive = false;
        }
      });
    }
  }

  void _handleRemoveAll() {
    if (widget.onRemoveAllAction == null || _localCartQty <= 0) return;

    widget.onRemoveAllAction!();

    if (mounted) {
      setState(() {
        if (widget.stock != null) _availableStock += _localCartQty;

        if (_localTotal != null && widget.rawPrice != null) {
          _localTotal = _localTotal! - (widget.rawPrice! * _localCartQty);
        }

        _localCartQty = 0;

        // 💡 RE-EVALUAMOS PROMOCIÓN AL VACIAR
        if (widget.promoThreshold != null &&
            (_localCartQty + widget.otherItemsInPromo) <
                widget.promoThreshold!) {
          _localPromoActive = false;
        }
      });
    }
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String key,
    String value, {
    Color? color,
    bool isBold = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: trailing != null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: trailing != null ? 1 : 3,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? theme.colorScheme.onSurface,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutOfStock = widget.stock != null && _availableStock <= 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.unitPrice,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),

          if (widget.stock != null)
            _buildDetailRow(
              context,
              Icons.inventory_2_outlined,
              'Stock disponible',
              isOutOfStock ? 'Agotado' : 'Quedan $_availableStock uds',
              color: isOutOfStock ? Colors.red : null,
              isBold: isOutOfStock,
            ),

          if (_localCartQty > 0)
            _buildDetailRow(
              context,
              Icons.shopping_cart_outlined,
              'En el carrito',
              '$_localCartQty uds',
              trailing: widget.onRemoveAction != null
                  ? Material(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _handleRemove,
                        onLongPress: _handleRemoveAll,
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.remove,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),

          if (widget.packContents != null && widget.packContents!.isNotEmpty)
            _buildDetailRow(
              context,
              Icons.widgets_outlined,
              'Contenido',
              widget.packContents!,
            ),

          if (widget.promoName != null) ...[
            _buildDetailRow(
              context,
              Icons.local_offer_outlined,
              'Promoción',
              widget.promoName!,
            ),
            _buildDetailRow(
              context,
              _localPromoActive
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              'Estado',
              _localPromoActive
                  ? 'Oferta aplicada'
                  // 💡 Pequeña ayuda visual en el texto si tiene combinados
                  : (widget.otherItemsInPromo > 0
                        ? 'Faltan uds (combinando $_localCartQty + ${widget.otherItemsInPromo})'
                        : 'Faltan uds para activar'),
              color: _localPromoActive
                  ? Colors.green
                  : theme.colorScheme.tertiary,
              isBold: _localPromoActive,
            ),
          ],

          if (_localCartQty > 0 && _localTotal != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.payments_outlined,
              'Total acumulado',
              '${_localTotal!.toStringAsFixed(2)} €',
              color: theme.colorScheme.primary,
              isBold: true,
            ),
          ],

          if (widget.onAction != null) ...[
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final Color bgColor = isOutOfStock
                    ? theme.colorScheme.surfaceContainerHighest
                    : (_justAdded
                          ? Colors.green.shade600
                          : theme.colorScheme.primary);

                final Color fgColor = isOutOfStock
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : Colors.white;

                final double elevation = isOutOfStock
                    ? 0
                    : (_justAdded ? 2 : 6);

                final String buttonText = isOutOfStock
                    ? 'Agotado'
                    : (_justAdded
                          ? '¡Añadido!'
                          : (widget.actionLabel ??
                                (_localCartQty > 0
                                    ? 'Añadir otra unidad'
                                    : 'Añadir al carrito')));

                final IconData buttonIcon = isOutOfStock
                    ? Icons.remove_shopping_cart_rounded
                    : (_justAdded
                          ? Icons.check_circle_rounded
                          : (widget.actionIcon ??
                                Icons.shopping_cart_checkout_rounded));

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.35),
                        blurRadius: elevation * 2.5,
                        offset: Offset(0, elevation * 0.8),
                      ),
                    ],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isOutOfStock ? null : _handleTap,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            key: ValueKey<String>(
                              '${_justAdded}_$isOutOfStock',
                            ),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(buttonIcon, color: fgColor, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                buttonText,
                                style: TextStyle(
                                  color: fgColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showItemPreview(
  BuildContext context, {
  required Widget image,
  required String title,
  required String unitPrice,
  double? rawPrice,
  int cartQty = 0,
  int otherItemsInPromo = 0, // 💡 AÑADIDO
  num? cartTotal,
  int? stock,
  String? promoName,
  bool promoActive = false,
  int? promoThreshold,
  String? packContents,
  String? actionLabel,
  IconData? actionIcon,
  VoidCallback? onAction,
  VoidCallback? onRemoveAction,
  VoidCallback? onRemoveAllAction,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar vista previa',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final theme = Theme.of(dialogContext);
      final media = MediaQuery.of(dialogContext);
      final isLandscape = media.size.width > media.size.height;

      final availableW = media.size.width - media.padding.horizontal - 32;
      final availableH = media.size.height - media.padding.vertical - 32;

      final info = _PreviewInfo(
        title: title,
        unitPrice: unitPrice,
        rawPrice: rawPrice,
        cartQty: cartQty,
        otherItemsInPromo: otherItemsInPromo, // 💡 PASADO AL WIDGET
        cartTotal: cartTotal,
        stock: stock,
        promoName: promoName,
        promoActive: promoActive,
        promoThreshold: promoThreshold,
        packContents: packContents,
        actionLabel: actionLabel,
        actionIcon: actionIcon,
        onAction: onAction,
        onRemoveAction: onRemoveAction,
        onRemoveAllAction: onRemoveAllAction,
      );

      final Widget cardLayout;

      if (isLandscape) {
        final cardHeight = math.min(availableH, 460.0);
        final cardWidth = math.min(availableW, cardHeight + 400);
        final imageWidth = math.min(cardHeight, cardWidth * 0.5);

        cardLayout = SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: imageWidth, child: image),
              Expanded(child: SingleChildScrollView(child: info)),
            ],
          ),
        );
      } else {
        final cardWidth = math.min(availableW, 420.0);
        final imageHeight = math.min(cardWidth, availableH * 0.45);

        cardLayout = SizedBox(
          width: cardWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: availableH),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: imageHeight, child: image),
                  info,
                ],
              ),
            ),
          ),
        );
      }

      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: theme.cardColor,
              elevation: 12,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  cardLayout,
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: 'Cerrar',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)).animate(animation);

      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

void showCartProductPreview(
  BuildContext context, {
  required Product product,
  required int qty,
  required num itemTotal,
  Promotion? promo,
  int otherItemsInPromo = 0, // 💡 RECIBE EL PARÁMETRO
  VoidCallback? onAddAction,
  VoidCallback? onRemoveAction,
  VoidCallback? onRemoveAllAction,
}) {
  // 💡 EVALÚA EL COMBINADO TOTAL
  final active = isPromoActive(promo, qty + otherItemsInPromo);

  showItemPreview(
    context,
    image: buildProductImage(product),
    title: product.name,
    unitPrice: '${product.price.toStringAsFixed(2)} € / ud',
    rawPrice: product.price,
    cartQty: qty,
    otherItemsInPromo: otherItemsInPromo, // 💡 SE LO PASA AL POPUP
    cartTotal: itemTotal,
    stock: product.units,
    promoName: promo?.name,
    promoActive: active,
    promoThreshold: promo?.threshold,
    actionLabel: qty > 0 ? 'Añadir otra unidad' : 'Añadir al carrito',
    actionIcon: Icons.add_shopping_cart,
    onAction: onAddAction,
    onRemoveAction: onRemoveAction,
    onRemoveAllAction: onRemoveAllAction,
  );
}

void showCartPackPreview(
  BuildContext context, {
  required Pack pack,
  required int qty,
  required num itemTotal,
  VoidCallback? onAddAction,
  VoidCallback? onRemoveAction,
  VoidCallback? onRemoveAllAction,
}) {
  final contents = pack.items.map((item) => item.productName).join(', ');

  showItemPreview(
    context,
    image: buildPackImage(pack),
    title: pack.name,
    unitPrice: '${pack.price.toStringAsFixed(2)} € / pack',
    rawPrice: pack.price,
    cartQty: qty,
    cartTotal: itemTotal,
    stock: pack.units,
    packContents: contents,
    actionLabel: qty > 0 ? 'Añadir otro pack' : 'Añadir al carrito',
    actionIcon: Icons.library_add_outlined,
    onAction: onAddAction,
    onRemoveAction: onRemoveAction,
    onRemoveAllAction: onRemoveAllAction,
  );
}
