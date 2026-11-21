import 'package:flutter/material.dart';
import 'package:keepinventory/core/theme/app_colors.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../domain/cash_change.dart';

/// Calculadora de vueltas para cobrar en efectivo: se marca lo que entrega el
/// cliente (con atajos de billetes) y se ve al momento lo que hay que devolver.
/// Es solo una ayuda: no bloquea el cobro ni se guarda en la venta.
class CashChangeCalculator extends StatefulWidget {
  const CashChangeCalculator({super.key, required this.total});

  final double total;

  /// Altura aproximada que ocupa, para reservar hueco en el carrito.
  static const double height = 112;

  @override
  State<CashChangeCalculator> createState() => _CashChangeCalculatorState();
}

class _CashChangeCalculatorState extends State<CashChangeCalculator> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _given => AppNumbers.parseDecimal(_controller.text);

  void _setGiven(double amount) {
    setState(() => _controller.text = context.amountInput(amount));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final given = _given;
    final diff = given == null
        ? null
        : CashChange.differenceCents(widget.total, given);

    Widget result() {
      if (diff == null) return const SizedBox.shrink();
      final missing = diff < 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            missing
                ? context.l10n.cashMissing(context.amount(-diff / 100))
                : context.l10n.cashChangeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: missing ? AppColors.warning : colors.onSurfaceVariant,
            ),
          ),
          if (!missing)
            Text(
              context.money(diff / 100),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
        ],
      );
    }

    final chips = <Widget>[
      ActionChip(
        label: Text(context.l10n.cashExact),
        onPressed: () => _setGiven(widget.total),
      ),
      for (final bill in CashChange.quickBills(widget.total))
        ActionChip(
          label: Text(context.money(bill.toDouble())),
          onPressed: () => _setGiven(bill.toDouble()),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: TextField(
                controller: _controller,
                keyboardType: AppNumbers.decimalKeyboard,
                inputFormatters: AppNumbers.decimalInputFormatters,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.l10n.cashGiven,
                  suffixText: '€',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 4, child: result()),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final chip in chips) ...[
                chip,
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
