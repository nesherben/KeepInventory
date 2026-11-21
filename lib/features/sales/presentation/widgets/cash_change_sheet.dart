import 'package:flutter/material.dart';
import 'package:keepinventory/core/theme/app_colors.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/adaptive_form.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../domain/cash_change.dart';

/// Abre la calculadora de vueltas. Devuelve true si se pulsó COBRAR dentro.
Future<bool> showCashChangeSheet(
  BuildContext context, {
  required double total,
}) async {
  final result = await AdaptiveForm.show<bool>(
    context,
    builder: (_) => CashChangeSheet(total: total),
  );
  return result ?? false;
}

/// Calculadora de vueltas para cobrar en efectivo: se tocan los billetes y
/// monedas que entrega el cliente, se van sumando y se ve al momento lo que hay
/// que devolver. Es solo una ayuda: no se guarda en la venta ni en el ticket.
class CashChangeSheet extends StatefulWidget {
  const CashChangeSheet({super.key, required this.total});

  final double total;

  @override
  State<CashChangeSheet> createState() => _CashChangeSheetState();
}

class _CashChangeSheetState extends State<CashChangeSheet> {
  /// Lo marcado, en orden (para poder deshacer el último).
  final List<int> _entries = [];

  int get _given => CashChange.sum(_entries);

  void _add(int cents) => setState(() => _entries.add(cents));

  Widget _figure(
    String label,
    String value, {
    Color? color,
    double size = 20,
  }) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _denominations(
    String title,
    List<int> values, {
    required bool filled,
  }) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(80, 52)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title, padding: const EdgeInsets.only(bottom: 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cents in values)
              filled
                  ? FilledButton.tonal(
                      style: style,
                      onPressed: () => _add(cents),
                      child: Text(context.money(cents / 100)),
                    )
                  : OutlinedButton(
                      style: style,
                      onPressed: () => _add(cents),
                      child: Text(context.money(cents / 100)),
                    ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final diff = CashChange.differenceCents(widget.total, _given);
    final missing = diff < 0;

    return AdaptiveFormScaffold(
      title: context.l10n.cashCalculatorTitle,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.close),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.point_of_sale, size: 18),
          label: Text(context.l10n.checkout),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _figure(
                      context.l10n.cashTotal,
                      context.money(widget.total),
                    ),
                    _figure(
                      context.l10n.cashGiven,
                      context.money(_given / 100),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // El dato que importa: lo que hay que devolver
                if (missing)
                  Text(
                    context.l10n.cashMissing(context.amount(-diff / 100)),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  )
                else
                  Row(
                    children: [
                      _figure(
                        context.l10n.cashChangeLabel,
                        context.money(diff / 100),
                        color: colors.primary,
                        size: 32,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _denominations(
            context.l10n.cashBills,
            CashChange.billCents,
            filled: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          _denominations(
            context.l10n.cashCoins,
            CashChange.coinCents,
            filled: false,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.check, size: 16),
                label: Text(context.l10n.cashExact),
                onPressed: () => setState(() {
                  _entries
                    ..clear()
                    ..add(CashChange.cents(widget.total));
                }),
              ),
              TextButton.icon(
                onPressed: _entries.isEmpty
                    ? null
                    : () => setState(_entries.removeLast),
                icon: const Icon(Icons.undo, size: 18),
                label: Text(context.l10n.cashUndo),
              ),
              TextButton.icon(
                onPressed: _entries.isEmpty
                    ? null
                    : () => setState(_entries.clear),
                icon: const Icon(Icons.clear_all, size: 18),
                label: Text(context.l10n.cashClear),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
