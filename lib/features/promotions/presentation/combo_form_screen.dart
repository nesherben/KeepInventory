import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/shared_widgets/app_ui.dart';
import '../../inventory/domain/product.dart';
import '../data/datasources/combo_local_datasource.dart';
import '../data/repositories/combo_repository_impl.dart';
import '../domain/combo.dart';

/// Borrador editable de un hueco: un producto y cuántas unidades lleva.
class _SlotDraft {
  _SlotDraft({this.productId, this.quantity = 1});

  int? productId;
  int quantity;
}

/// Crear / editar un combo: nombre, productos (cada uno con su cantidad)
/// y precio, con el ahorro frente a comprar por separado en vivo.
/// Devuelve `true` al guardar.
class ComboFormScreen extends StatefulWidget {
  const ComboFormScreen({
    super.key,
    this.combo,
    required this.products,
    required this.otherCombos,
  });

  final Combo? combo;

  /// Productos activos.
  final List<Product> products;

  /// Resto de combos: un producto solo puede estar en uno.
  final List<Combo> otherCombos;

  @override
  State<ComboFormScreen> createState() => _ComboFormScreenState();
}

class _ComboFormScreenState extends State<ComboFormScreen> {
  final _repository = ComboRepositoryImpl(ComboLocalDatasource());
  final _name = TextEditingController();
  final _price = TextEditingController();
  late final List<_SlotDraft> _slots;
  late final Map<int, Product> _productsById;
  late final Map<int, String> _productCombo;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final combo = widget.combo;
    _name.text = combo?.name ?? '';
    _slots = combo == null
        ? [_SlotDraft(), _SlotDraft()]
        : [
            for (final s in combo.slots)
              _SlotDraft(
                productId: s.productIds.isEmpty ? null : s.productIds.first,
                quantity: s.quantity,
              ),
          ];
    _productsById = {
      for (final p in widget.products)
        if (p.id != null) p.id!: p,
    };
    _productCombo = {
      for (final c in widget.otherCombos)
        for (final id in c.productIds) id: c.name,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El precio se rellena con el formato local (necesita el contexto)
    if (!_initialized && widget.combo != null) {
      _price.text = context.amountInput(widget.combo!.price);
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Precio por separado: precio de cada producto × cantidad.
  double get _separateTotal => _slots.fold(
    0.0,
    (t, slot) =>
        t + (_productsById[slot.productId]?.price ?? 0.0) * slot.quantity,
  );

  double? get _priceValue => AppNumbers.parseDecimal(_price.text);

  Future<void> _pickProduct(_SlotDraft slot) async {
    final usedElsewhere = {
      for (final other in _slots)
        if (!identical(other, slot) && other.productId != null)
          other.productId!,
    };
    var query = '';

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          final visible = widget.products
              .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.comboSlotPickTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setSheet(() => query = v),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchProduct,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final product = visible[index];
                      final id = product.id!;
                      final otherCombo = _productCombo[id];
                      final inOtherSlot = usedElsewhere.contains(id);
                      final disabled = otherCombo != null || inOtherSlot;
                      return ListTile(
                        enabled: !disabled,
                        selected: slot.productId == id,
                        minVerticalPadding: 10,
                        onTap: () => Navigator.pop(context, id),
                        title: Text(product.name),
                        subtitle: Text(
                          otherCombo != null
                              ? context.l10n.comboProductInOtherCombo(
                                  otherCombo,
                                )
                              : inOtherSlot
                              ? context.l10n.comboProductInOtherSlot
                              : context.money(product.price),
                        ),
                        trailing: slot.productId == id
                            ? const Icon(Icons.check)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (result != null) setState(() => slot.productId = result);
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = _priceValue;
    String? error;
    if (name.isEmpty) {
      error = context.l10n.comboErrorName;
    } else if (_slots.length < 2) {
      error = context.l10n.comboErrorMinSlots;
    } else if (_slots.any((s) => s.productId == null)) {
      error = context.l10n.comboErrorEmptySlot;
    } else if (price == null || price < 0) {
      error = context.l10n.invalidNumber;
    }
    if (error != null) {
      AppAlerts.showError(context, error);
      return;
    }

    if (price! >= _separateTotal &&
        !await _confirm(
          context.l10n.comboNoSavingTitle,
          context.l10n.comboNoSavingWarning,
        )) {
      return;
    }
    if (!mounted) return;

    // Gana el combo: se avisa de los productos con promoción propia
    final withPromo = {
      for (final s in _slots)
        if (_productsById[s.productId]?.promotionId != null)
          _productsById[s.productId]!.name,
    };
    if (withPromo.isNotEmpty &&
        !await _confirm(
          context.l10n.comboOwnPromoTitle,
          context.l10n.comboOwnPromoWarning(withPromo.join(', ')),
        )) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.saveCombo(
        Combo(
          id: widget.combo?.id,
          name: name,
          price: price,
          slots: [
            for (final s in _slots)
              ComboSlot(
                name: _productsById[s.productId]?.name ?? '',
                quantity: s.quantity,
                productIds: [s.productId!],
              ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    AppAlerts.showSuccess(context, context.l10n.comboSaved);
    Navigator.pop(context, true);
  }

  Widget _buildSlot(int index) {
    final slot = _slots[index];
    final colors = Theme.of(context).colorScheme;
    final product = _productsById[slot.productId];
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => _pickProduct(slot),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product?.name ?? context.l10n.comboSlotNoProducts,
                            style: TextStyle(
                              color: product == null
                                  ? colors.primary
                                  : colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (product != null)
                            Text(
                              context.money(product.price),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          QuantityStepper(
            label: '×${slot.quantity}',
            onIncrement: () => setState(() => slot.quantity++),
            onDecrement: slot.quantity > 1
                ? () => setState(() => slot.quantity--)
                : null,
          ),
          IconButton(
            tooltip: context.l10n.delete,
            icon: Icon(Icons.delete_outline, color: colors.error),
            onPressed: _slots.length > 2
                ? () => setState(() => _slots.removeAt(index))
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final separate = _separateTotal;
    final price = _priceValue;
    final saving = price == null ? null : separate - price;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.combo == null
              ? context.l10n.comboNewTitle
              : context.l10n.comboEditTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(context.l10n.save),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.page(context)),
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.l10n.comboNameLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionLabel(
                context.l10n.comboSlotsSection,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              for (var i = 0; i < _slots.length; i++) _buildSlot(i),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _slots.add(_SlotDraft())),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.comboSlotAdd),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _price,
                keyboardType: AppNumbers.decimalKeyboard,
                inputFormatters: AppNumbers.decimalInputFormatters,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.l10n.comboPriceLabel,
                  suffixText: '€',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const IconBadge(Icons.extension),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.l10n.comboSeparateTotal(
                          context.amount(separate),
                        ),
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                    if (saving != null && saving > 0)
                      Text(
                        context.l10n.comboSaving(context.amount(saving)),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
