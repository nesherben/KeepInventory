import 'package:flutter/material.dart';
import 'package:keepinventory/core/shared_widgets/app_alerts.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/sale.dart';
import '../../domain/sale_refund_calculator.dart';

typedef PartialRefundHandler = Future<void> Function({
  required Map<SaleItem, int> itemsToRefund,
  required Map<SalePackItem, int> packsToRefund,
  required bool restockAsComponents,
  required double customRefundAmount,
});

class PartialRefundDialog extends StatefulWidget {
  const PartialRefundDialog({
    super.key,
    required this.sale,
    required this.onConfirm,
  });

  final Sale sale;
  final PartialRefundHandler onConfirm;

  @override
  State<PartialRefundDialog> createState() => _PartialRefundDialogState();
}

class _PartialRefundDialogState extends State<PartialRefundDialog> {
  late final Map<SaleItem, int> _refundItemQuantities;
  late final Map<SalePackItem, int> _refundPackQuantities;
  final _refundAmountController = TextEditingController(text: '0.00');
  bool _restockAsComponents = false;

  int get _totalItemsToRefund =>
      _refundItemQuantities.values.fold(
        0,
        (total, quantity) => total + quantity,
      ) +
      _refundPackQuantities.values.fold(
        0,
        (total, quantity) => total + quantity,
      );

  bool get _hasPacksSelected =>
      _refundPackQuantities.values.any((quantity) => quantity > 0);

  @override
  void initState() {
    super.initState();
    _refundItemQuantities = {for (final item in widget.sale.items) item: 0};
    _refundPackQuantities = {for (final pack in widget.sale.packItems) pack: 0};
  }

  @override
  void dispose() {
    _refundAmountController.dispose();
    super.dispose();
  }

  void _recalculateDefaultRefund() {
    // Cantidades del ticket original (antes de devolver nada).
    final originalItemQuantities = {
      for (final item in widget.sale.items) item: item.quantity,
    };
    final keptItemQuantities = {
      for (final item in widget.sale.items)
        item: item.quantity - (_refundItemQuantities[item] ?? 0),
    };
    final keptPackQuantities = {
      for (final pack in widget.sale.packItems)
        pack: pack.quantity - (_refundPackQuantities[pack] ?? 0),
    };
    final remainingValue = SaleRefundCalculator.calculateRemainingCartValue(
      originalItemQuantities: originalItemQuantities,
      keptItemQuantities: keptItemQuantities,
      keptPackQuantities: keptPackQuantities,
    );
    final refundAmount = (widget.sale.totalAmount - remainingValue).clamp(
      0.0,
      double.infinity,
    );

    _refundAmountController.text = refundAmount.toStringAsFixed(2);
  }

  Widget _buildProductRow(BuildContext context, SaleItem item) {
    final colors = Theme.of(context).colorScheme;
    return _buildRefundLine(
      context,
      title: item.productName ?? context.l10n.unknown,
      summary: context.l10n.purchasedItemSummary(
        item.quantity.toString(),
        (item.quantity * item.historicalPrice).toStringAsFixed(2),
      ),
      value: _refundItemQuantities[item] ?? 0,
      maxValue: item.quantity,
      backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
      borderColor: colors.outlineVariant.withValues(alpha: 0.5),
      onChanged: (value) {
        setState(() => _refundItemQuantities[item] = value);
        _recalculateDefaultRefund();
      },
    );
  }

  Widget _buildPackRow(BuildContext context, SalePackItem pack) {
    final colors = Theme.of(context).colorScheme;
    return _buildRefundLine(
      context,
      title: context.l10n.packNameLabel(
        pack.packName ?? context.l10n.unknownPackDeleted,
      ),
      summary: context.l10n.purchasedPackSummary(
        pack.quantity.toString(),
        (pack.quantity * pack.historicalPrice).toStringAsFixed(2),
      ),
      value: _refundPackQuantities[pack] ?? 0,
      maxValue: pack.quantity,
      backgroundColor: colors.secondaryContainer.withValues(alpha: 0.3),
      borderColor: colors.secondaryContainer,
      onChanged: (value) {
        setState(() => _refundPackQuantities[pack] = value);
        _recalculateDefaultRefund();
      },
    );
  }

  Widget _buildRefundLine(
    BuildContext context, {
    required String title,
    required String summary,
    required int value,
    required int maxValue,
    required Color backgroundColor,
    required Color borderColor,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _RefundQuantitySelector(
              value: value,
              maxValue: maxValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestockSwitch(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: SwitchListTile(
        dense: true,
        title: Text(
          context.l10n.openPackRestock,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          context.l10n.openPackRestockSubtitle,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
        value: _restockAsComponents,
        activeThumbColor: colors.error,
        onChanged: (value) => setState(() => _restockAsComponents = value),
      ),
    );
  }

  Widget _buildRefundAmountField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.refundTotalLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _refundAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: colors.error,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colors.errorContainer.withValues(alpha: 0.1),
            prefixIcon: Icon(Icons.payments, color: colors.error),
            isDense: true,
            helperText: context.l10n.refundAutoHelp,
            helperMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRefund() async {
    final refundAmount =
        double.tryParse(_refundAmountController.text.replaceAll(',', '.')) ??
        0.0;
    if (refundAmount > widget.sale.totalAmount) {
      AppAlerts.showError(context, context.l10n.refundCannotExceed);
      return;
    }

    Navigator.pop(context);
    await widget.onConfirm(
      itemsToRefund: _refundItemQuantities,
      packsToRefund: _refundPackQuantities,
      restockAsComponents: _restockAsComponents,
      customRefundAmount: refundAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.refundTitle(widget.sale.id.toString()),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.refundInstruction,
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (widget.sale.items.isNotEmpty) ...[
                Text(
                  context.l10n.looseProducts,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.sale.items.map(
                  (item) => _buildProductRow(context, item),
                ),
                const SizedBox(height: 8),
              ],
              if (widget.sale.packItems.isNotEmpty) ...[
                Text(
                  context.l10n.packsBundles,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.sale.packItems.map(
                  (pack) => _buildPackRow(context, pack),
                ),
                if (_hasPacksSelected) ...[
                  const SizedBox(height: 8),
                  _buildRestockSwitch(context),
                ],
              ],
              const Divider(height: 32),
              _buildRefundAmountField(context),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.cancel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _totalItemsToRefund == 0 ? null : _confirmRefund,
          icon: const Icon(Icons.undo, size: 18),
          label: Text(
            context.l10n.confirm,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _RefundQuantitySelector extends StatelessWidget {
  const _RefundQuantitySelector({
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: colors.error, size: 18),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          IconButton(
            icon: Icon(Icons.add, color: colors.primary, size: 18),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: value < maxValue ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
