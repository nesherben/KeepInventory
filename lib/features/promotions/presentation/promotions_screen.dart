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
    final saved = await showDialog<bool>(
      context: context,
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
    final colors = Theme.of(context).colorScheme;
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
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            onTap: () => _openComboForm(combo),
            leading: const IconBadge(Icons.extension),
            title: Text(
              combo.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              saving > 0
                  ? '$slots · ${context.money(combo.price)}\n'
                        '${context.l10n.comboSaving(context.amount(saving))}'
                  : '$slots · ${context.money(combo.price)}',
            ),
            isThreeLine: saving > 0,
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              onPressed: () => _confirmDeleteCombo(combo),
            ),
          ),
        );
      },
    );
  }

  void _showPromotionFormDialog({Promotion? promotionToEdit}) {
    final isEditing = promotionToEdit != null;
    showDialog(
      context: context,
      builder: (dialogContext) => PromotionFormDialog(
        promotion: promotionToEdit,
        onSave: (promotion) async {
          if (isEditing) {
            await _repository.updatePromotion(promotion);
          } else {
            await _repository.insertPromotion(promotion);
          }
          if (!mounted) return;
          _loadPromotions();
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
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredPromotions.length,
                              itemBuilder: (context, index) {
                                final promo = filteredPromotions[index];
                                final isBundle =
                                    promo.type == 'bundle_fixed_price';

                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.fromLTRB(
                                      12,
                                      6,
                                      4,
                                      6,
                                    ),
                                    leading: IconBadge(
                                      isBundle ? Icons.layers : Icons.percent,
                                      color: AppColors.warning,
                                    ),
                                    title: Text(
                                      promo.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      isBundle
                                          ? context.l10n.promotionBundleSummary(
                                              promo.threshold.toString(),
                                              context.amount(
                                                promo.discountValue,
                                              ),
                                            )
                                          : context.l10n
                                                .promotionPercentSummary(
                                                  promo.discountValue
                                                      .toStringAsFixed(0),
                                                  promo.threshold.toString(),
                                                ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          onPressed: () =>
                                              _showPromotionFormDialog(
                                                promotionToEdit: promo,
                                              ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          onPressed: () =>
                                              _confirmDelete(promo),
                                        ),
                                      ],
                                    ),
                                  ),
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
