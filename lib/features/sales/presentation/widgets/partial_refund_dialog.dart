import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/shared_widgets/adaptive_form.dart';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/core/shared_widgets/app_alerts.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/sale.dart';
import '../../domain/sale_refund_calculator.dart';
import 'payment_method_widgets.dart';

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
  final _refundAmountController = TextEditingController(text: '0');
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
      combos: widget.sale.combos,
      adjustmentFactor: widget.sale.adjustmentFactor,
    );
    final refundAmount = (widget.sale.totalAmount - remainingValue).clamp(
      0.0,
      double.infinity,
    );

    _refundAmountController.text = context.amountInput(refundAmount);
  }

  Widget _buildProductRow(BuildContext context, SaleItem item) {
    final colors = Theme.of(context).colorScheme;
    return _buildRefundLine(
      context,
      title: item.productName ?? context.l10n.unknown,
      summary: context.l10n.purchasedItemSummary(
        item.quantity.toString(),
        context.amount(
          item.quantity *
              item.historicalPrice *
              widget.sale.adjustmentFactor,
        ),
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

  /// Combos de la venta con sus líneas, y líneas sueltas.
  List<Widget> _buildProductRows(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final widgets = <Widget>[];
    final grouped = <SaleItem>{};
    for (final combo in widget.sale.combos) {
      final lines = widget.sale.items
          .where((i) => i.saleComboId == combo.id)
          .toList();
      if (lines.isEmpty) continue;
      grouped.addAll(lines);
      final selected = lines.any((i) => (_refundItemQuantities[i] ?? 0) > 0);
      final whole = lines.every(
        (i) => (_refundItemQuantities[i] ?? 0) == i.quantity,
      );
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.extension, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.comboCartTitle(combo.name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: whole
                    ? null
                    : () {
                        setState(() {
                          for (final line in lines) {
                            _refundItemQuantities[line] = line.quantity;
                          }
                        });
                        _recalculateDefaultRefund();
                      },
                child: Text(context.l10n.comboRefundWhole),
              ),
            ],
          ),
        ),
      );
      if (selected && !whole) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: colors.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.comboRefundBreaks(combo.name),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      widgets.addAll(lines.map((line) => _buildProductRow(context, line)));
      widgets.add(const SizedBox(height: 8));
    }
    for (final item in widget.sale.items) {
      if (!grouped.contains(item)) widgets.add(_buildProductRow(context, item));
    }
    return widgets;
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
        context.amount(
          pack.quantity *
              pack.historicalPrice *
              widget.sale.adjustmentFactor,
        ),
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

  /// Aviso por cada promoción que deshace la devolución (p. ej. devolver 1
  /// de "3 por 12 €"): explica por qué se devuelve menos o nada.
  List<Widget> _buildPromotionWarnings(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final broken = SaleRefundCalculator.brokenPromotions(
      sale: widget.sale,
      itemsToRefund: _refundItemQuantities,
    );
    return [
      for (final item in broken)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: colors.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.promotionRefundBreaks(
                    item.promoType == 'bundle_fixed_price'
                        ? context.l10n.promotionAutoNameBundle(
                            item.promoThreshold!,
                            context.amount(item.promoDiscount ?? 0),
                          )
                        : context.l10n.promotionAutoNamePercent(
                            item.promoThreshold!,
                            context.percent(
                              item.promoDiscount ?? 0,
                              maxDecimals: 2,
                            ),
                          ),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _buildRefundAmountField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final method = widget.sale.paymentMethod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.refundTotalLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        // La devolución se hace siempre por el método de pago original
        PaymentMethodBadge(
          method: method,
          text: method == PaymentMethod.unspecified
              ? context.l10n.refundMethodUnknown
              : context.l10n.refundViaMethod(method.label(context)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _refundAmountController,
          keyboardType: AppNumbers.decimalKeyboard,
          inputFormatters: AppNumbers.decimalInputFormatters,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: colors.error,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colors.errorContainer.withValues(alpha: 0.1),
            prefixIcon: Icon(method.icon, color: colors.error),
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
        AppNumbers.parseDecimal(_refundAmountController.text) ?? 0.0;
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
    // Mismo formato que el resto de formularios (panel en el móvil,
    // lateral en tablet horizontal, diálogo en vertical)
    return AdaptiveFormScaffold(
      title: context.l10n.refundTitle(widget.sale.id.toString()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        // En rojo: devuelve dinero y repone stock
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: _totalItemsToRefund == 0 ? null : _confirmRefund,
          icon: const Icon(Icons.undo, size: 18),
          label: Text(context.l10n.confirm),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.refundInstruction,
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (widget.sale.items.isNotEmpty) ...[
            SectionLabel(
              context.l10n.looseProducts,
              padding: const EdgeInsets.only(bottom: 8),
            ),
            ..._buildProductRows(context),
            const SizedBox(height: 8),
          ],
          if (widget.sale.packItems.isNotEmpty) ...[
            SectionLabel(
              context.l10n.packsBundles,
              padding: const EdgeInsets.only(bottom: 8),
            ),
            ...widget.sale.packItems.map(
              (pack) => _buildPackRow(context, pack),
            ),
            if (_hasPacksSelected) ...[
              const SizedBox(height: 8),
              _buildRestockSwitch(context),
            ],
          ],
          ..._buildPromotionWarnings(context),
          const Divider(height: 32),
          _buildRefundAmountField(context),
        ],
      ),
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
        border: Border.all(color: Theme.of(context).dividerColor),
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
