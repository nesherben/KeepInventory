import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/adaptive_form.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/manual_line_discount.dart';

/// Resultado de la hoja: [discount] null = quitar el descuento de la línea.
class LineDiscountResult {
  final ManualLineDiscount? discount;

  const LineDiscountResult(this.discount);
}

/// Abre la hoja de descuento de una línea. Devuelve null si se cierra sin
/// decidir nada.
Future<LineDiscountResult?> showLineDiscountSheet(
  BuildContext context, {
  required String productName,
  required int quantity,
  required double lineSubtotal,
  ManualLineDiscount? current,
}) {
  return AdaptiveForm.show<LineDiscountResult>(
    context,
    builder: (_) => LineDiscountSheet(
      productName: productName,
      quantity: quantity,
      lineSubtotal: lineSubtotal,
      current: current,
    ),
  );
}

enum _Mode { percent, amount, finalPrice }

/// Descuento manual sobre el TOTAL de una línea: porcentaje, importe o precio
/// final. La vista previa se recalcula al teclear.
class LineDiscountSheet extends StatefulWidget {
  const LineDiscountSheet({
    super.key,
    required this.productName,
    required this.quantity,
    required this.lineSubtotal,
    this.current,
  });

  final String productName;
  final int quantity;

  /// Total de la línea antes del descuento.
  final double lineSubtotal;
  final ManualLineDiscount? current;

  @override
  State<LineDiscountSheet> createState() => _LineDiscountSheetState();
}

class _LineDiscountSheetState extends State<LineDiscountSheet> {
  static const _quickPercents = [5, 10, 20];

  final _controller = TextEditingController();
  _Mode _mode = _Mode.percent;
  bool _seeded = false;

  /// Un segundo toque durante la animación de cierre haría otro pop y
  /// cerraría la pantalla de Ventas.
  bool _closing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final current = widget.current;
    if (current == null) return;
    // Al reabrir se muestra el descuento tal y como se aplicó
    _mode = current.type == ManualDiscountType.percent
        ? _Mode.percent
        : _Mode.amount;
    _controller.text = context.amountInput(current.value);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  double? get _value => AppNumbers.parseDecimal(_controller.text);

  /// Descuento que sale de lo tecleado (null si no es válido).
  ManualLineDiscount? get _candidate {
    final value = _value;
    final subtotal = widget.lineSubtotal;
    if (value == null || !value.isFinite) return null;
    switch (_mode) {
      case _Mode.percent:
        // Un % tan pequeño que no baja ni un céntimo no cuenta como descuento
        return value > 0 &&
                value <= 100 &&
                ManualLineDiscount.percent(value).discountOn(subtotal) > 0
            ? ManualLineDiscount.percent(value)
            : null;
      case _Mode.amount:
        return value > 0 && value <= subtotal
            ? ManualLineDiscount.amount(value)
            : null;
      case _Mode.finalPrice:
        return value >= 0 && value < subtotal
            ? ManualLineDiscount.fromFinalPrice(
                finalTotal: value,
                lineTotal: subtotal,
              )
            : null;
    }
  }

  String? _errorText(BuildContext context) {
    if (_controller.text.trim().isEmpty || _candidate != null) return null;
    final max = context.amount(widget.lineSubtotal);
    switch (_mode) {
      case _Mode.percent:
        return context.l10n.lineDiscountErrorPercent;
      case _Mode.amount:
        return context.l10n.lineDiscountErrorAmount(max);
      case _Mode.finalPrice:
        return context.l10n.lineDiscountErrorFinal(max);
    }
  }

  /// Cambia de modo convirtiendo el valor, en vez de borrarlo.
  void _setMode(_Mode mode) {
    if (mode == _mode) return;
    final candidate = _candidate;
    var text = _controller.text;
    if (candidate != null) {
      final converted = switch (mode) {
        _Mode.percent => candidate.percentOf(widget.lineSubtotal),
        _Mode.amount => candidate.discountOn(widget.lineSubtotal),
        _Mode.finalPrice => candidate.apply(widget.lineSubtotal),
      };
      text = context.amountInput(converted);
    }
    setState(() {
      _mode = mode;
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  void _setPercent(int percent) {
    final text = percent.toString();
    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  void _apply() {
    final candidate = _candidate;
    if (candidate == null || _closing) return;
    _closing = true;
    Navigator.pop(context, LineDiscountResult(candidate));
  }

  void _remove() {
    if (_closing) return;
    _closing = true;
    Navigator.pop(context, const LineDiscountResult(null));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final candidate = _candidate;
    final after = candidate?.apply(widget.lineSubtotal);
    final saving = candidate?.discountOn(widget.lineSubtotal);

    return AdaptiveFormScaffold(
      title: context.l10n.lineDiscountTitle(widget.productName),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: _remove,
            child: Text(context.l10n.lineDiscountRemove),
          ),
        FilledButton(
          onPressed: candidate == null ? null : _apply,
          child: Text(context.l10n.lineDiscountApply),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.lineDiscountLineInfo(
              widget.quantity,
              context.amount(widget.lineSubtotal),
            ),
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<_Mode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _Mode.percent,
                label: Text(context.l10n.lineDiscountModePercent),
              ),
              ButtonSegment(
                value: _Mode.amount,
                label: Text(context.l10n.lineDiscountModeAmount),
              ),
              ButtonSegment(
                value: _Mode.finalPrice,
                label: Text(context.l10n.lineDiscountModeFinal),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) => _setMode(selection.first),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: AppNumbers.decimalKeyboard,
            inputFormatters: AppNumbers.decimalInputFormatters,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: switch (_mode) {
                _Mode.percent => context.l10n.lineDiscountPercentLabel,
                _Mode.amount => context.l10n.lineDiscountAmountLabel,
                _Mode.finalPrice => context.l10n.lineDiscountFinalLabel,
              },
              suffixText: _mode == _Mode.percent ? '%' : '€',
              errorText: _errorText(context),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _apply(),
          ),
          if (_mode == _Mode.percent) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final percent in _quickPercents)
                  ActionChip(
                    label: Text(context.percent(percent.toDouble())),
                    onPressed: () => _setPercent(percent),
                  ),
              ],
            ),
          ],
          if (candidate != null && after != null && saving != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.lineDiscountBefore,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          context.money(widget.lineSubtotal),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.lineDiscountAfter,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          context.money(after),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '−${context.money(saving)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (after <= 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.lineDiscountFreeLine,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
