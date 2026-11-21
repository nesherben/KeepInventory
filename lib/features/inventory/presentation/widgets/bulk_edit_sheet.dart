import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/adaptive_form.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../promotions/domain/promotion.dart';
import '../../domain/bulk_product_edit.dart';
import '../../domain/product_category.dart';
import 'category_picker.dart';
import 'promotion_picker.dart';

/// Hoja para cambiar varios productos a la vez: categoría, promoción, precio y
/// coste. Todo empieza en "No cambiar"; solo se toca lo que se elige.
/// Devuelve null si se cierra sin aplicar.
Future<BulkProductEdit?> showBulkEditSheet(
  BuildContext context, {
  required int count,
  required List<Promotion> promotions,
}) {
  return AdaptiveForm.show<BulkProductEdit>(
    context,
    builder: (_) => _BulkEditSheet(count: count, promotions: promotions),
  );
}

class _BulkEditSheet extends StatefulWidget {
  const _BulkEditSheet({required this.count, required this.promotions});

  final int count;
  final List<Promotion> promotions;

  @override
  State<_BulkEditSheet> createState() => _BulkEditSheetState();
}

class _BulkEditSheetState extends State<_BulkEditSheet> {
  bool _categoryChanged = false;
  ProductCategory? _category;
  bool _promotionChanged = false;
  Promotion? _promotion;

  BulkNumberMode _priceMode = BulkNumberMode.keep;
  BulkNumberMode _costMode = BulkNumberMode.keep;
  final _priceController = TextEditingController();
  final _costController = TextEditingController();

  /// Un segundo toque durante la animación de cierre haría otro pop.
  bool _closing = false;

  @override
  void dispose() {
    _priceController.dispose();
    _costController.dispose();
    super.dispose();
  }

  /// Cambio numérico a partir de lo tecleado (null si falta o no es válido).
  BulkNumberEdit? _numberEdit(
    BulkNumberMode mode,
    TextEditingController controller,
  ) {
    if (mode == BulkNumberMode.keep) return const BulkNumberEdit.keep();
    final value = AppNumbers.parseDecimal(controller.text);
    if (value == null || !value.isFinite) return null;
    // Fijar un precio negativo no tiene sentido
    if (mode == BulkNumberMode.set && value < 0) return null;
    return BulkNumberEdit(mode, value);
  }

  BulkProductEdit? get _edit {
    final price = _numberEdit(_priceMode, _priceController);
    final cost = _numberEdit(_costMode, _costController);
    if (price == null || cost == null) return null;
    final edit = BulkProductEdit(
      changeCategory: _categoryChanged,
      categoryId: _category?.id,
      changePromotion: _promotionChanged,
      promotionId: _promotion?.id,
      price: price,
      cost: cost,
    );
    return edit.isEmpty ? null : edit;
  }

  Future<void> _pickCategory() async {
    final pick = await pickCategory(context, currentId: _category?.id);
    if (pick == null || !mounted) return;
    setState(() {
      _categoryChanged = true;
      _category = pick.category;
    });
  }

  Future<void> _pickPromotion() async {
    final pick = await pickPromotion(
      context,
      promotions: widget.promotions,
      currentId: _promotion?.id,
    );
    if (pick == null || !mounted) return;
    setState(() {
      _promotionChanged = true;
      _promotion = pick.promotion;
    });
  }

  void _apply() {
    final edit = _edit;
    if (edit == null || _closing) return;
    _closing = true;
    Navigator.pop(context, edit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return AdaptiveFormScaffold(
      title: l10n.bulkEditTitle(widget.count),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _edit == null ? null : _apply,
          child: Text(l10n.bulkEditApply),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.bulkEditHint,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PickerField(
            icon: Icons.sell_outlined,
            label: l10n.productCategory,
            value: !_categoryChanged
                ? null
                : (_category?.name ?? l10n.categoryNone),
            keepLabel: l10n.bulkKeep,
            onTap: _pickCategory,
            onClear: () => setState(() => _categoryChanged = false),
          ),
          const SizedBox(height: AppSpacing.md),
          _PickerField(
            icon: Icons.local_offer_outlined,
            label: l10n.historyFieldPromotion,
            value: !_promotionChanged
                ? null
                : (_promotion?.name ?? l10n.noPromotion),
            keepLabel: l10n.bulkKeep,
            onTap: _pickPromotion,
            onClear: () => setState(() => _promotionChanged = false),
          ),
          const SizedBox(height: AppSpacing.lg),
          _NumberEditor(
            label: l10n.fieldSalePrice,
            mode: _priceMode,
            controller: _priceController,
            onModeChanged: (mode) => setState(() => _priceMode = mode),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          _NumberEditor(
            label: l10n.fieldAcquisitionCost,
            mode: _costMode,
            controller: _costController,
            onModeChanged: (mode) => setState(() => _costMode = mode),
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}

/// Campo de solo lectura que abre un selector; vacío = "No cambiar".
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.keepLabel,
    required this.onTap,
    required this.onClear,
  });

  final IconData icon;
  final String label;

  /// null = no se cambia.
  final String? value;
  final String keepLabel;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: value == null
              ? const Icon(Icons.arrow_drop_down)
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          value ?? keepLabel,
          style: TextStyle(
            color: value == null ? colors.onSurfaceVariant : null,
            fontWeight: value == null ? null : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Precio o coste: "No cambiar", fijar un valor, o subir/bajar un % o un €.
class _NumberEditor extends StatelessWidget {
  const _NumberEditor({
    required this.label,
    required this.mode,
    required this.controller,
    required this.onModeChanged,
    required this.onChanged,
  });

  final String label;
  final BulkNumberMode mode;
  final TextEditingController controller;
  final ValueChanged<BulkNumberMode> onModeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final signed =
        mode == BulkNumberMode.percent || mode == BulkNumberMode.amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<BulkNumberMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: BulkNumberMode.keep,
              label: Text(l10n.bulkKeepShort),
            ),
            ButtonSegment(value: BulkNumberMode.set, label: Text(l10n.bulkSet)),
            ButtonSegment(
              value: BulkNumberMode.percent,
              label: Text(l10n.bulkPercent),
            ),
            ButtonSegment(
              value: BulkNumberMode.amount,
              label: Text(l10n.bulkAmount),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        if (mode != BulkNumberMode.keep) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: signed
                ? AppNumbers.signedDecimalKeyboard
                : AppNumbers.decimalKeyboard,
            inputFormatters: signed
                ? AppNumbers.signedDecimalInputFormatters
                : AppNumbers.decimalInputFormatters,
            decoration: InputDecoration(
              suffixText: mode == BulkNumberMode.percent ? '%' : '€',
            ),
            onChanged: (_) => onChanged(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(switch (mode) {
              BulkNumberMode.set => l10n.bulkHelpSet,
              BulkNumberMode.percent => l10n.bulkHelpPercent,
              _ => l10n.bulkHelpAmount,
            }, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          ),
        ],
      ],
    );
  }
}
