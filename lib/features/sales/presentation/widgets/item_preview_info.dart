import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

class ItemPreviewInfo extends StatefulWidget {
  const ItemPreviewInfo({
    super.key,
    required this.title,
    required this.unitPrice,
    this.rawPrice,
    this.cartQty = 0,
    this.cartTotal,
    this.stock,
    this.promoName,
    this.promoActive = false,
    this.promoThreshold,
    this.packContents,
    this.otherItemsInPromo = 0,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.onRemoveAction,
    this.onRemoveAllAction,
  });

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
  final int otherItemsInPromo;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onRemoveAction;
  final VoidCallback? onRemoveAllAction;

  @override
  State<ItemPreviewInfo> createState() => _ItemPreviewInfoState();
}

class _ItemPreviewInfoState extends State<ItemPreviewInfo> {
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
    _localPromoActive = widget.promoThreshold != null
        ? _localCartQty + widget.otherItemsInPromo >= widget.promoThreshold!
        : widget.promoActive;
  }

  Future<void> _handleTap() async {
    if (widget.onAction == null ||
        (widget.stock != null && _availableStock <= 0)) {
      return;
    }

    widget.onAction!();
    if (!mounted) return;

    setState(() {
      _justAdded = true;
      _localCartQty++;
      if (widget.stock != null) _availableStock--;
      if (_localTotal != null && widget.rawPrice != null) {
        _localTotal = _localTotal! + widget.rawPrice!;
      }
      if (widget.promoThreshold != null &&
          _localCartQty + widget.otherItemsInPromo >= widget.promoThreshold!) {
        _localPromoActive = true;
      }
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _justAdded = false);
  }

  void _handleRemove() {
    if (widget.onRemoveAction == null || _localCartQty <= 0) return;

    widget.onRemoveAction!();
    if (!mounted) return;

    setState(() {
      _localCartQty--;
      if (widget.stock != null) _availableStock++;
      if (_localTotal != null && widget.rawPrice != null) {
        _localTotal = _localTotal! - widget.rawPrice!;
      }
      if (widget.promoThreshold != null &&
          _localCartQty + widget.otherItemsInPromo < widget.promoThreshold!) {
        _localPromoActive = false;
      }
    });
  }

  void _handleRemoveAll() {
    if (widget.onRemoveAllAction == null || _localCartQty <= 0) return;

    widget.onRemoveAllAction!();
    if (!mounted) return;

    setState(() {
      if (widget.stock != null) _availableStock += _localCartQty;
      if (_localTotal != null && widget.rawPrice != null) {
        _localTotal = _localTotal! - widget.rawPrice! * _localCartQty;
      }
      _localCartQty = 0;
      if (widget.promoThreshold != null &&
          _localCartQty + widget.otherItemsInPromo < widget.promoThreshold!) {
        _localPromoActive = false;
      }
    });
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: trailing == null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: trailing == null ? 3 : 1,
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

  Widget _buildActionButton(BuildContext context, bool isOutOfStock) {
    final theme = Theme.of(context);
    final backgroundColor = isOutOfStock
        ? theme.colorScheme.surfaceContainerHighest
        : (_justAdded ? Colors.green.shade600 : theme.colorScheme.primary);
    final foregroundColor = isOutOfStock
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
        : Colors.white;
    final elevation = isOutOfStock ? 0.0 : (_justAdded ? 2.0 : 6.0);
    final label = isOutOfStock
        ? context.l10n.outOfStock
        : (_justAdded
              ? context.l10n.added
              : (widget.actionLabel ??
                    (_localCartQty > 0
                        ? context.l10n.addAnotherUnit
                        : context.l10n.addToCart)));
    final icon = isOutOfStock
        ? Icons.remove_shopping_cart_rounded
        : (_justAdded
              ? Icons.check_circle_rounded
              : (widget.actionIcon ?? Icons.shopping_cart_checkout_rounded));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.35),
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
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Row(
                key: ValueKey('${_justAdded}_$isOutOfStock'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: foregroundColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
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
              context.l10n.stockAvailable,
              isOutOfStock
                  ? context.l10n.outOfStock
                  : context.l10n.unitsRemaining(_availableStock.toString()),
              color: isOutOfStock ? Colors.red : null,
              isBold: isOutOfStock,
            ),
          if (_localCartQty > 0)
            _buildDetailRow(
              context,
              Icons.shopping_cart_outlined,
              context.l10n.inCart,
              context.l10n.unitCount(_localCartQty.toString()),
              trailing: widget.onRemoveAction == null
                  ? null
                  : Material(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _handleRemove,
                        onLongPress: _handleRemoveAll,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.remove,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
            ),
          if (widget.packContents != null && widget.packContents!.isNotEmpty)
            _buildDetailRow(
              context,
              Icons.widgets_outlined,
              context.l10n.packContents,
              widget.packContents!,
            ),
          if (widget.promoName != null) ...[
            _buildDetailRow(
              context,
              Icons.local_offer_outlined,
              context.l10n.promotion,
              widget.promoName!,
            ),
            _buildDetailRow(
              context,
              _localPromoActive
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              context.l10n.status,
              _localPromoActive
                  ? context.l10n.offerApplied
                  : (widget.otherItemsInPromo > 0
                        ? context.l10n.promotionShortfallCombined(
                            _localCartQty.toString(),
                            widget.otherItemsInPromo.toString(),
                          )
                        : context.l10n.promotionShortfall),
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
              context.l10n.totalAccumulated,
              '${_localTotal!.toStringAsFixed(2)} €',
              color: theme.colorScheme.primary,
              isBold: true,
            ),
          ],
          if (widget.onAction != null) ...[
            const SizedBox(height: 24),
            _buildActionButton(context, isOutOfStock),
          ],
        ],
      ),
    );
  }
}
