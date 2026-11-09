import '../../../core/shared_widgets/adaptive_form.dart';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_ui.dart';
import '../domain/promotion.dart';

/// Crear / editar una promoción. El tipo se elige con dos botones y una
/// frase en vivo explica la regla; el nombre se sugiere solo ("3 por 12 €")
/// mientras el usuario no escriba uno propio.
class PromotionFormDialog extends StatefulWidget {
  const PromotionFormDialog({super.key, this.promotion, required this.onSave});

  final Promotion? promotion;

  final Future<void> Function(Promotion promotion) onSave;

  @override
  State<PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<PromotionFormDialog> {
  static const _bundle = 'bundle_fixed_price';
  static const _percent = 'percentage';

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _threshold = TextEditingController();
  final _value = TextEditingController();
  late String _type;
  String _lastAutoName = '';
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final promo = widget.promotion;
    _type = promo?.type ?? _bundle;
    _name.text = promo?.name ?? '';
    _threshold.text = (promo?.threshold ?? (_type == _bundle ? 3 : 2))
        .toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final promo = widget.promotion;
    if (promo != null) {
      _value.text = _formatValue(promo.discountValue);
      // Si el nombre guardado coincide con el automático, sigue siéndolo
      if (promo.name == _autoName()) _lastAutoName = promo.name;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _threshold.dispose();
    _value.dispose();
    super.dispose();
  }

  String _formatValue(double v) => _type == _bundle
      ? context.amountInput(v)
      : (v == v.roundToDouble()
            ? v.round().toString()
            : context.amountInput(v));

  int? get _count => AppNumbers.parseInt(_threshold.text);
  double? get _amount => AppNumbers.parseDecimal(_value.text);

  /// Nombre sugerido según los valores ("" si aún no están completos).
  String _autoName() {
    final n = _count;
    final v = _amount;
    if (n == null || n < 1 || v == null || v <= 0) return '';
    return _type == _bundle
        ? context.l10n.promotionAutoNameBundle(n, context.amount(v))
        : context.l10n.promotionAutoNamePercent(
            n,
            context.percent(v, maxDecimals: 2),
          );
  }

  /// Actualiza el nombre si está vacío o sigue siendo el automático.
  void _onValuesChanged() {
    final suggestion = _autoName();
    final current = _name.text.trim();
    if (current.isEmpty || current == _lastAutoName) {
      _name.text = suggestion;
      _lastAutoName = suggestion;
    }
    setState(() {});
  }

  String? _preview() {
    final n = _count;
    final v = _amount;
    if (n == null || n < 1 || v == null || v <= 0) return null;
    if (_type == _percent && v > 100) return null;
    return _type == _bundle
        ? context.l10n.promotionPreviewBundle(n, context.amount(v))
        : context.l10n.promotionPreviewPercent(
            n,
            context.percent(v, maxDecimals: 2),
          );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        Promotion(
          id: widget.promotion?.id,
          name: _name.text.trim(),
          type: _type,
          threshold: _count!,
          discountValue: _amount!,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isBundle = _type == _bundle;
    final preview = _preview();

    return AdaptiveFormScaffold(
      title: widget.promotion == null
          ? context.l10n.promotionFormNewTitle
          : context.l10n.promotionFormEditTitle,
      dialogWidth: 480,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            widget.promotion == null ? context.l10n.save : context.l10n.update,
          ),
        ),
      ],
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _bundle,
                    icon: const Icon(Icons.layers),
                    label: Text(context.l10n.promotionTypeBundle),
                  ),
                  ButtonSegment(
                    value: _percent,
                    icon: const Icon(Icons.percent),
                    label: Text(context.l10n.promotionTypePercent),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (v) {
                  _type = v.first;
                  _onValuesChanged();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _threshold,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.l10n.minimumQuantity,
                        suffixText: context.l10n.unitCount('').trim(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: AppNumbers.integerInputFormatters,
                      onChanged: (_) => _onValuesChanged(),
                      validator: (value) {
                        final n = AppNumbers.parseInt(value);
                        return n == null || n < 1
                            ? context.l10n.validNumberRequired
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _value,
                      autofocus: widget.promotion == null,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: isBundle
                            ? context.l10n.bundleTotalPrice
                            : context.l10n.discountPercentage,
                        suffixText: isBundle ? '€' : '%',
                      ),
                      keyboardType: AppNumbers.decimalKeyboard,
                      inputFormatters: AppNumbers.decimalInputFormatters,
                      onChanged: (_) => _onValuesChanged(),
                      validator: (value) {
                        final v = AppNumbers.parseDecimal(value);
                        // % entre 0 y 100; precio del lote > 0
                        final invalid =
                            v == null || v <= 0 || (!isBundle && v > 100);
                        return invalid ? context.l10n.validValueRequired : null;
                      },
                    ),
                  ),
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(preview)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: InputDecoration(labelText: context.l10n.offerName),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.l10n.required
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
