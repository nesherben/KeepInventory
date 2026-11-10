import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

enum _CartTotalAction { adjust, reset }

class SalesCartTotalSummary extends StatelessWidget {
  const SalesCartTotalSummary({
    super.key,
    required this.baseTotal,
    required this.total,
    required this.itemCount,
    required this.fontSize,
    required this.hasAdjustment,
    required this.onTotalAdjusted,
    required this.onReset,
    this.color,
  });

  final double baseTotal;
  final double total;
  final int itemCount;
  final double fontSize;
  final bool hasAdjustment;
  final Color? color;
  final ValueChanged<double> onTotalAdjusted;
  final VoidCallback onReset;

  Future<void> _adjustTotal(BuildContext context) async {
    if (baseTotal <= 0) return;

    final controller = TextEditingController(text: context.amountInput(total));
    final agreedTotal = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final value = AppNumbers.parseDecimal(controller.text);
              if (value == null || !value.isFinite || value < 0) {
                setDialogState(() {
                  errorText = context.l10n.salesInvalidAgreedTotal;
                });
                return;
              }
              Navigator.pop(dialogContext, value);
            }

            return AlertDialog(
              title: Text(context.l10n.salesAdjustTotal),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.salesCartAdjustmentHint),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: AppNumbers.decimalKeyboard,
                    inputFormatters: AppNumbers.decimalInputFormatters,
                    decoration: InputDecoration(
                      labelText: context.l10n.salesAgreedTotal,
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(onPressed: submit, child: Text(context.l10n.save)),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (context.mounted && agreedTotal != null) {
      onTotalAdjusted(agreedTotal);
    }
  }

  Widget _buildMenu(BuildContext context) => PopupMenuButton<_CartTotalAction>(
    enabled: itemCount > 0,
    tooltip: context.l10n.salesAdjustTotal,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    iconSize: 20,
    onSelected: (action) {
      switch (action) {
        case _CartTotalAction.adjust:
          _adjustTotal(context);
        case _CartTotalAction.reset:
          onReset();
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem(
        value: _CartTotalAction.adjust,
        child: Text(context.l10n.salesAdjustTotal),
      ),
      if (hasAdjustment)
        PopupMenuItem(
          value: _CartTotalAction.reset,
          child: Text(context.l10n.salesResetTotalAdjustment),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasAdjustment)
          Text(
            context.money(baseTotal),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
              fontSize: 12,
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              context.l10n.cartTotal(context.amount(total)),
              style: textStyle,
            ),
            const SizedBox(width: 4),
            SizedBox(width: 40, height: 40, child: _buildMenu(context)),
          ],
        ),
      ],
    );
  }
}
