import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../inventory/domain/product.dart';
import '../../../packs/domain/pack.dart';
import '../../../promotions/domain/promotion.dart';
import 'item_preview_info.dart';

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

Future<void> showItemPreview(
  BuildContext context, {
  required Widget image,
  required String title,
  required String unitPrice,
  double? rawPrice,
  int cartQty = 0,
  int otherItemsInPromo = 0,
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
    barrierLabel: context.l10n.closePreview,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final theme = Theme.of(dialogContext);
      final media = MediaQuery.of(dialogContext);
      final isLandscape = media.size.width > media.size.height;

      final availableW = media.size.width - media.padding.horizontal - 32;
      final availableH = media.size.height - media.padding.vertical - 32;

      final info = ItemPreviewInfo(
        title: title,
        unitPrice: unitPrice,
        rawPrice: rawPrice,
        cartQty: cartQty,
        otherItemsInPromo: otherItemsInPromo,
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
                        tooltip: context.l10n.closePreview,
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
  int otherItemsInPromo = 0,
  VoidCallback? onAddAction,
  VoidCallback? onRemoveAction,
  VoidCallback? onRemoveAllAction,
}) {
  final active = isPromoActive(promo, qty + otherItemsInPromo);

  showItemPreview(
    context,
    image: buildProductImage(product),
    title: product.name,
    unitPrice: context.l10n.pricePerUnit(product.price.toStringAsFixed(2)),
    rawPrice: product.price,
    cartQty: qty,
    otherItemsInPromo: otherItemsInPromo,
    cartTotal: itemTotal,
    stock: product.units,
    promoName: promo?.name,
    promoActive: active,
    promoThreshold: promo?.threshold,
    actionLabel: qty > 0 ? context.l10n.addAnotherUnit : context.l10n.addToCart,
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
  final contents = pack.items
      .map((item) => item.productName ?? context.l10n.unknownDeleted)
      .join(', ');

  showItemPreview(
    context,
    image: buildPackImage(pack),
    title: pack.name,
    unitPrice: context.l10n.pricePerPack(pack.price.toStringAsFixed(2)),
    rawPrice: pack.price,
    cartQty: qty,
    cartTotal: itemTotal,
    stock: pack.units,
    packContents: contents,
    actionLabel: qty > 0 ? context.l10n.addAnotherPack : context.l10n.addToCart,
    actionIcon: Icons.library_add_outlined,
    onAction: onAddAction,
    onRemoveAction: onRemoveAction,
    onRemoveAllAction: onRemoveAllAction,
  );
}
