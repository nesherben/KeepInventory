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

/// Calculadora de vueltas para cobrar en efectivo. Arriba, dos columnas: lo que
/// entrega el cliente y las vueltas con los billetes y monedas a devolver.
/// Abajo, los botones de billetes y monedas que se van sumando (sin escribir
/// nada). Es solo una ayuda: no se guarda en la venta ni en el ticket.
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

  Widget _caption(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  /// Tarjeta de la izquierda: total a cobrar y lo entregado.
  Widget _givenCard() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _caption(context.l10n.cashTotal),
        Text(
          context.money(widget.total),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        _caption(context.l10n.cashGiven),
        Text(
          context.money(_given / 100),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  /// Tarjeta de la derecha: vueltas y con qué piezas devolverlas.
  Widget _changeCard(int diff) {
    final colors = Theme.of(context).colorScheme;
    if (diff < 0) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _caption(context.l10n.cashChangeLabel),
            const SizedBox(height: 2),
            Text(
              context.l10n.cashMissing(context.amount(-diff / 100)),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }
    final pieces = CashChange.breakdown(diff);
    return AppCard(
      borderColor: diff > 0 ? colors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _caption(context.l10n.cashChangeLabel),
          Text(
            context.money(diff / 100),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
          if (pieces.isNotEmpty) ...[
            const Divider(height: 20),
            for (final entry in pieces.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${entry.value} × ${context.money(entry.key / 100)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buttons(List<int> values, {required bool filled}) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
    // Rejilla regular: 3 por fila en el móvil, 6 si hay sitio (tablet)
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final columns = constraints.maxWidth >= 520 ? 6 : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final cents in values)
              SizedBox(
                width: width,
                child: filled
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
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final diff = CashChange.differenceCents(widget.total, _given);

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
          // Dos columnas: lo entregado y las vueltas a devolver
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _givenCard()),
                const SizedBox(width: 12),
                Expanded(child: _changeCard(diff)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Abajo, solo botones: billetes (rellenos) y monedas (con borde)
          _buttons(CashChange.billCents, filled: true),
          const SizedBox(height: 8),
          _buttons(CashChange.coinCents, filled: false),
          const SizedBox(height: AppSpacing.md),
          Row(
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
              const Spacer(),
              IconButton(
                tooltip: context.l10n.cashUndo,
                onPressed: _entries.isEmpty
                    ? null
                    : () => setState(_entries.removeLast),
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: context.l10n.cashClear,
                onPressed: _entries.isEmpty
                    ? null
                    : () => setState(_entries.clear),
                icon: const Icon(Icons.clear_all),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
