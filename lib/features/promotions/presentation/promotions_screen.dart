import '../../inventory/presentation/widgets/product_picker_sheet.dart';
import '../../../core/shared_widgets/adaptive_form.dart';
import 'widgets/offer_card.dart';
import '../../inventory/presentation/widgets/category_picker.dart';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/shared_widgets/app_ui.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart'; // 💡 Sistema de alertas en cola

import '../data/repositories/promotion_repository_impl.dart';
import '../domain/promotion.dart';
import '../data/datasources/promotion_local_datasource.dart';
import '../../inventory/data/datasources/product_local_datasource.dart';
import '../../inventory/data/repositories/product_repository_impl.dart';
import '../../inventory/data/datasources/category_local_datasource.dart';
import '../../inventory/data/repositories/category_repository_impl.dart';
import '../../inventory/domain/product_category.dart';
import '../../inventory/domain/product.dart';
import '../data/datasources/combo_local_datasource.dart';
import '../data/repositories/combo_repository_impl.dart';
import '../domain/combo.dart';
import 'combo_form_screen.dart';
import 'promotion_form_dialog.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _repository = PromotionRepositoryImpl(PromotionLocalDatasource());
  final _comboRepository = ComboRepositoryImpl(ComboLocalDatasource());
  final _productRepository = ProductRepositoryImpl(ProductLocalDatasource());

  // Llave y variables para el gesto global de deslizamiento
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  double? _startX;
  double? _startY;

  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String _searchQuery = ''; // 💡 Variable para el buscador

  /// 0 = promociones, 1 = combos.
  int _tab = 0;
  List<Combo> _combos = [];
  List<Product> _products = [];
  List<ProductCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    // Sin indicador de carga al recargar: se conserva la posición del scroll
    final promotions = await _repository.getPromotions();
    final combos = await _comboRepository.getCombos();
    final products = await _productRepository.getProducts();
    final categories = await CategoryRepositoryImpl(CategoryLocalDatasource())
        .getCategories();
    if (!mounted) return;
    setState(() {
      _promotions = promotions;
      _combos = combos;
      _products = products;
      _categories = categories;
      _isLoading = false;
    });
  }

  // --- Combos ---

  Future<void> _openComboForm([Combo? combo]) async {
    final saved = await AdaptiveForm.show<bool>(
      context,
      builder: (_) => ComboFormScreen(
        combo: combo,
        products: _products,
        otherCombos: _combos.where((c) => c.id != combo?.id).toList(),
        categories: _categories,
      ),
    );
    if (saved == true) _loadPromotions();
  }

  void _confirmDeleteCombo(Combo combo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.comboDeleteTitle),
        content: Text(context.l10n.comboDeleteConfirm(combo.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await _comboRepository.deleteCombo(combo.id!);
              if (context.mounted) {
                Navigator.pop(context);
                _loadPromotions();
                AppAlerts.showWarning(context, context.l10n.comboDeleted);
              }
            },
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildComboList() {
    final byId = {for (final p in _products) p.id: p};
    final combos = _combos
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    if (combos.isEmpty) {
      return EmptyState(
        icon: Icons.extension_outlined,
        title: _combos.isEmpty
            ? context.l10n.combosEmpty
            : context.l10n.promotionsNotFound,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: combos.length,
      itemBuilder: (context, index) {
        final combo = combos[index];
        final separate = combo.separatePrice((id) => byId[id]?.price ?? 0);
        final saving = separate - combo.price;
        final slots = combo.slots
            .map((s) {
              final label = s.isCategory
                  ? context.l10n.comboSlotAnyOf(s.name)
                  : s.name;
              return s.quantity > 1 ? '${s.quantity} × $label' : label;
            })
            .join(' + ');
        return OfferCard(
          icon: Icons.extension,
          title: combo.name,
          lines: ['$slots · ${context.money(combo.price)}'],
          highlight: saving > 0
              ? context.l10n.comboSaving(context.amount(saving))
              : null,
          onTap: () => _openComboForm(combo),
          actions: [
            OfferAction(
              icon: Icons.edit_outlined,
              label: context.l10n.edit,
              onTap: () => _openComboForm(combo),
            ),
            OfferAction(
              icon: Icons.delete_outline,
              label: context.l10n.delete,
              destructive: true,
              onTap: () => _confirmDeleteCombo(combo),
            ),
          ],
        );
      },
    );
  }

  /// Tras crear una promoción: ¿a qué productos se aplica?
  Future<void> _askWhereToApply(Promotion promo) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.promotionAssignTitle(promo.name),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(l10n.promotionAssignCategory),
              onTap: () => Navigator.pop(context, 'category'),
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(l10n.promotionAssignProducts),
              onTap: () => Navigator.pop(context, 'products'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.promotionAssignLater),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'category') await _applyToCategory(promo);
    if (choice == 'products') await _chooseProducts(promo);
  }

  /// Marca con casillas los productos que llevan la promoción (los que se
  /// desmarcan se quedan sin promoción).
  Future<void> _chooseProducts(Promotion promo) async {
    final initial = {
      for (final p in _products)
        if (p.promotionId == promo.id) p.id!,
    };
    final selected = await showProductMultiPicker(
      context,
      products: _products,
      initiallySelected: initial,
      title: context.l10n.promotionAssignTitle(promo.name),
    );
    if (selected == null || !mounted) return;
    for (final id in selected.difference(initial)) {
      await _productRepository.updateFields(id, promotionId: promo.id);
    }
    for (final id in initial.difference(selected)) {
      await _productRepository.updateFields(id, clearPromotion: true);
    }
    if (!mounted) return;
    AppAlerts.showSuccess(
      context,
      context.l10n.promotionAppliedToProducts(selected.length),
    );
    _loadPromotions();
  }

  /// Pone la promoción a todos los productos de una categoría (una vez;
  /// después cada producto se puede cambiar por separado).
  Future<void> _applyToCategory(Promotion promo) async {
    final pick = await pickCategory(context);
    final category = pick?.category;
    if (category == null || !mounted) return;
    final count = _products.where((p) => p.categoryId == category.id).length;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.promotionApplyConfirmTitle),
        content: Text(
          l10n.promotionApplyConfirm(count, promo.name, category.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.apply),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final changed = await _productRepository.setPromotionForCategory(
      category.id,
      promo.id!,
    );
    if (!mounted) return;
    AppAlerts.showSuccess(
      context,
      l10n.promotionAppliedToCategory(changed, category.name),
    );
    _loadPromotions();
  }

  void _showPromotionFormDialog({Promotion? promotionToEdit}) {
    final isEditing = promotionToEdit != null;
    AdaptiveForm.show(
      context,
      builder: (dialogContext) => PromotionFormDialog(
        promotion: promotionToEdit,
        onSave: (promotion) async {
          Promotion saved = promotion;
          if (isEditing) {
            await _repository.updatePromotion(promotion);
          } else {
            final id = await _repository.insertPromotion(promotion);
            saved = Promotion(
              id: id,
              name: promotion.name,
              type: promotion.type,
              threshold: promotion.threshold,
              discountValue: promotion.discountValue,
            );
          }
          if (!mounted) return;
          _loadPromotions();
          // Recién creada: no se aplica a nada hasta asignarla
          if (!isEditing) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _askWhereToApply(saved),
            );
          }
          AppAlerts.showSuccess(
            context,
            isEditing
                ? context.l10n.promotionUpdatedSuccess
                : context.l10n.promotionCreated,
          );
        },
      ),
    );
  }

  // --- DIÁLOGO DE CONFIRMACIÓN DE BORRADO ---
  void _confirmDelete(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deletePromotionTitle),
        content: Text(context.l10n.confirmDeletePromotion(promotion.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await _repository.deletePromotion(promotion.id!);
              if (context.mounted) {
                Navigator.pop(context);
                _loadPromotions();
                // 💡 Alerta de advertencia/borrado
                AppAlerts.showWarning(context, context.l10n.promotionDeleted);
              }
            },
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Filtrado instantáneo por texto
    final filteredPromotions = _promotions.where((promo) {
      return promo.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Listener(
      onPointerDown: (event) {
        _startX = event.position.dx;
        _startY = event.position.dy;
      },
      onPointerMove: (event) {
        if (_startX == null || _startY == null) return;
        final dx = event.position.dx - _startX!;
        final dy = event.position.dy - _startY!;

        // Gesto horizontal hacia la derecha de más de 50px sin desviación vertical excesiva
        if (dx > 50 && dy.abs() < 30) {
          _startX = null;
          _startY = null;
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      onPointerUp: (_) {
        _startX = null;
        _startY = null;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: Text(context.l10n.navPromotions)),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // --- 💡 BARRA DE BÚSQUEDA ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchPromotion,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 0,
                            icon: const Icon(Icons.local_offer_outlined),
                            label: Text(context.l10n.promotionsTab),
                          ),
                          ButtonSegment(
                            value: 1,
                            icon: const Icon(Icons.extension_outlined),
                            label: Text(context.l10n.combosTab),
                          ),
                        ],
                        selected: {_tab},
                        onSelectionChanged: (v) =>
                            setState(() => _tab = v.first),
                      ),
                    ),
                  ),

                  // --- LISTADO DE PROMOCIONES ---
                  if (_tab == 1)
                    Expanded(child: _buildComboList())
                  else
                    Expanded(
                      child: filteredPromotions.isEmpty
                          ? EmptyState(
                              icon: Icons.local_offer_outlined,
                              title: _promotions.isEmpty
                                  ? context.l10n.promotionsEmpty
                                  : context.l10n.promotionsNotFound,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                96,
                              ),
                              itemCount: filteredPromotions.length,
                              itemBuilder: (context, index) {
                                final promo = filteredPromotions[index];
                                final isBundle =
                                    promo.type == 'bundle_fixed_price';

                                final count = _products
                                    .where((p) => p.promotionId == promo.id)
                                    .length;
                                return OfferCard(
                                  icon: isBundle ? Icons.layers : Icons.percent,
                                  iconColor: AppColors.warning,
                                  title: promo.name,
                                  lines: [
                                    isBundle
                                        ? context.l10n.promotionBundleSummary(
                                            promo.threshold.toString(),
                                            context.amount(promo.discountValue),
                                          )
                                        : context.l10n.promotionPercentSummary(
                                            promo.discountValue.toStringAsFixed(
                                              0,
                                            ),
                                            promo.threshold.toString(),
                                          ),
                                    context.l10n.promotionProductsCount(count),
                                  ],
                                  onTap: () => _showPromotionFormDialog(
                                    promotionToEdit: promo,
                                  ),
                                  actions: [
                                    OfferAction(
                                      icon: Icons.edit_outlined,
                                      label: context.l10n.edit,
                                      onTap: () => _showPromotionFormDialog(
                                        promotionToEdit: promo,
                                      ),
                                    ),
                                    OfferAction(
                                      icon: Icons.checklist,
                                      label:
                                          context.l10n.promotionAssignProducts,
                                      onTap: () => _chooseProducts(promo),
                                    ),
                                    OfferAction(
                                      icon: Icons.sell_outlined,
                                      label:
                                          context.l10n.promotionApplyToCategory,
                                      onTap: () => _applyToCategory(promo),
                                    ),
                                    OfferAction(
                                      icon: Icons.delete_outline,
                                      label: context.l10n.delete,
                                      destructive: true,
                                      onTap: () => _confirmDelete(promo),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              _tab == 1 ? _openComboForm() : _showPromotionFormDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
