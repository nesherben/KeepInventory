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

/// Calculadora de vueltas para cobrar en efectivo, compacta y sin scroll. En
/// tablet (panel lateral estrecho y alto) todo se apila en vertical: total y
/// entregado, vueltas, y billetes y monedas en bloques con su etiqueta.
/// Arriba, dos columnas: total y entregado a la izquierda; vueltas con las
/// piezas a devolver (en dos columnas) a la derecha. Debajo, las acciones y
/// una sola rejilla de billetes y monedas: cada pieza marcada lleva un
/// contador, como los productos del carrito. Es solo una ayuda: no se guarda
/// en la venta ni en el ticket.
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

  /// Tablet (panel lateral): todo un poco más grande.
  bool get _wide => !AdaptiveForm.isSheet(context);

  void _add(int cents) => setState(() => _entries.add(cents));

  int _count(int cents) => _entries.where((e) => e == cents).length;

  Widget _caption(String text) => Text(
    text,
    style: TextStyle(
      fontSize: _wide ? 14 : 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  /// Etiqueta y cifra grande que se encoge si no cabe.
  Widget _figure(String label, String value, {Color? color, double? size}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _caption(label),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: size ?? (_wide ? 26 : 20),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      );

  /// Columna izquierda: total y entregado.
  Widget _givenCard({bool row = false}) {
    final total = _figure(context.l10n.cashTotal, context.money(widget.total));
    final given = _figure(context.l10n.cashGiven, context.money(_given / 100));
    return AppCard(
      child: row
          ? Row(
              children: [
                Expanded(child: total),
                Expanded(child: given),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                total,
                const SizedBox(height: AppSpacing.sm),
                given,
              ],
            ),
    );
  }

  /// Columna derecha: vueltas y, en dos columnas, con qué piezas devolverlas.
  /// Reserva alto para cuatro filas de piezas para que la rejilla de abajo no
  /// se mueva al marcar.
  Widget _changeCard(int diff) {
    final colors = Theme.of(context).colorScheme;
    final missing = diff < 0;
    final pieces = missing ? const <int, int>{} : CashChange.breakdown(diff);
    final rowHeight = _wide ? 28.0 : 22.0;
    return AppCard(
      borderColor: diff > 0 ? colors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _figure(
            context.l10n.cashChangeLabel,
            missing
                ? context.l10n.cashMissing(context.amount(-diff / 100))
                : context.money(diff / 100),
            color: missing ? AppColors.warning : colors.primary,
            size: missing ? (_wide ? 22 : 18) : (_wide ? 34 : 28),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: rowHeight * (_wide ? 3 : 4)),
            // Filas de dos (sin LayoutBuilder: va dentro de un IntrinsicHeight)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < pieces.length; i += 2)
                  SizedBox(
                    height: rowHeight,
                    child: Row(
                      children: [
                        for (var j = i; j < i + 2; j++)
                          Expanded(
                            child: j < pieces.length
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${pieces.entries.elementAt(j).value} × '
                                      '${context.money(pieces.entries.elementAt(j).key / 100)}',
                                      style: TextStyle(
                                        fontSize: _wide ? 17 : 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Acciones siempre visibles, justo encima de la rejilla.
  Widget _actions() => Row(
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
      TextButton.icon(
        onPressed: _entries.isEmpty
            ? null
            : () => setState(_entries.removeLast),
        icon: const Icon(Icons.undo, size: 18),
        label: Text(context.l10n.cashUndo),
      ),
      TextButton.icon(
        onPressed: _entries.isEmpty ? null : () => setState(_entries.clear),
        icon: const Icon(Icons.clear_all, size: 18),
        label: Text(context.l10n.cashClear),
      ),
    ],
  );

  /// Contador de piezas marcadas (como el de los productos del carrito). Solo
  /// informa: para quitar piezas está Deshacer.
  Widget _badge(int count) {
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      top: 2,
      right: 2,
      child: IgnorePointer(
        child: Container(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '$count',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  /// Rejilla regular de billetes (rellenos) o monedas (con borde): 4 por fila
  /// en el móvil, 6 en tablet (una fila de billetes y otra de monedas).
  Widget _grid(List<int> values, {required bool filled}) {
    final wide = _wide;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, wide ? 60 : 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 4),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: wide ? 16 : 14, fontWeight: FontWeight.w600),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final columns = wide ? 6 : 4;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        Widget button(int cents) {
          final count = _count(cents);
          // El texto baja un poco para dejar sitio al contador, en la esquina
          final label = Padding(
            padding: EdgeInsets.only(top: wide ? 10 : 12),
            child: FittedBox(child: Text(context.money(cents / 100))),
          );
          return SizedBox(
            width: width,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                filled
                    ? FilledButton.tonal(
                        style: style,
                        onPressed: () => _add(cents),
                        child: label,
                      )
                    : OutlinedButton(
                        style: style,
                        onPressed: () => _add(cents),
                        child: label,
                      ),
                if (count > 0) _badge(count),
              ],
            ),
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final cents in values) button(cents)],
        );
      },
    );
  }

  /// Móvil: una sola rejilla con billetes y monedas. Tablet: dos bloques con
  /// etiqueta.
  List<Widget> _buttons() {
    if (!_wide) {
      return [
        _grid(CashChange.billCents, filled: true),
        const SizedBox(height: 8),
        _grid(CashChange.coinCents, filled: false),
      ];
    }
    return [
      SectionLabel(
        context.l10n.cashBills,
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 8),
      ),
      _grid(CashChange.billCents, filled: true),
      SectionLabel(
        context.l10n.cashCoins,
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 8),
      ),
      _grid(CashChange.coinCents, filled: false),
    ];
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
          if (_wide) ...[
            // Tablet: en vertical
            _givenCard(row: true),
            const SizedBox(height: AppSpacing.sm),
            _changeCard(diff),
          ] else
            // Móvil: dos columnas, total/entregado y vueltas
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: _givenCard()),
                  const SizedBox(width: 10),
                  Expanded(flex: 3, child: _changeCard(diff)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _actions(),
          const SizedBox(height: AppSpacing.sm),
          ..._buttons(),
        ],
      ),
    );
  }
}
