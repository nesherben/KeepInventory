import '../../../core/shared_widgets/app_side_rail.dart';
import 'categories_screen.dart';
import '../data/datasources/category_local_datasource.dart';
import '../data/repositories/category_repository_impl.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/shared_widgets/coach_marks.dart';
import 'widgets/bulk_edit_sheet.dart';
import 'widgets/inventory_product_widgets.dart';
import 'widgets/inventory_filters_bar.dart';
import '../domain/inventory_view.dart';

import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/shared_widgets/app_ui.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../packs/data/datasources/pack_local_datasource.dart';
import '../../packs/data/repositories/pack_repository_impl.dart';

import '../../../core/shared_widgets/app_drawer.dart';

// Imports de la feature INVENTORY
import '../../promotions/data/repositories/promotion_repository_impl.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/product.dart';
import '../data/datasources/product_local_datasource.dart';

// Imports de la feature PROMOTIONS
import '../../promotions/domain/promotion.dart';
import '../../promotions/data/datasources/promotion_local_datasource.dart';
import '../../promotions/data/datasources/combo_local_datasource.dart';
import '../../promotions/data/repositories/combo_repository_impl.dart';

// Widgets modularizados
import 'widgets/inventory_products_table.dart';
import 'inventory_product_editor.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  /// Ancho a partir del cual se muestra la tabla en vez de tarjetas.
  static const double _tableMinWidth = 700;

  final _productRepository = ProductRepositoryImpl(ProductLocalDatasource());
  final _promotionRepository = PromotionRepositoryImpl(
    PromotionLocalDatasource(),
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  double? _startX;
  double? _startY;

  List<Product> _products = [];
  Map<int, Promotion> _promotionsMap = {};

  /// Nombre del combo de cada producto (informativo).
  Map<int, String> _comboNames = {};
  Map<int, int> _packedUnits = {};

  /// Categorías (id -> nombre) y filtro por categoría (null = todas).
  Map<int, String> _categoryNames = {};
  int? _categoryFilter;
  bool _isLoading = true;

  // Guía de la pantalla (mini tutorial): elementos que se iluminan
  final _fabKey = GlobalKey();
  final _filtersKey = GlobalKey();
  final _selectKey = GlobalKey();
  bool _guideTried = false;

  String _searchQuery = '';
  InventoryFilter _filter = InventoryFilter.all;
  InventorySort? _sort;
  bool _sortAscending = true;

  /// +/− de stock aún sin guardar (por producto): se agrupan los toques
  /// rápidos y se guardan como una suma en la BD.
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, int> _pendingStock = {};

  /// Cada recarga lleva un número: si termina una antigua después de una
  /// nueva, se descarta.
  int _loadSeq = 0;

  /// Edición múltiple: productos marcados. Con la selección activa, tocar una
  /// tarjeta la marca en vez de editarla.
  bool _selecting = false;
  final Set<int> _selected = {};

  InventoryProductEditor get _productEditor => InventoryProductEditor(
    repository: _productRepository,
    promotions: () => _promotionsMap,
    categories: () => _categoryNames,
    reloadProducts: _loadProducts,
    discardPendingStock: _discardPendingStock,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    // Al salir de la pantalla se guarda lo pendiente (no se pierde)
    for (final entry in _pendingStock.entries) {
      _productRepository.addUnits(entry.key, entry.value);
    }
    _pendingStock.clear();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Recarga los datos. El indicador de carga solo se ve en la primera carga
  /// (`_isLoading` empieza en true): al recargar tras editar no se sustituye
  /// la lista, así se conserva la posición del scroll.
  Future<void> _loadProducts() async {
    final seq = ++_loadSeq;
    final fresh = await _productRepository.getProducts();
    final promotions = await _promotionRepository.getPromotions();
    final categories = await CategoryRepositoryImpl(CategoryLocalDatasource())
        .getCategories();
    final combos = await ComboRepositoryImpl(ComboLocalDatasource())
        .getCombos();

    final packs = await PackRepositoryImpl(PackLocalDatasource()).getPacks();
    // Unidades de cada producto encerradas en packs montados
    final packedUnits = <int, int>{};
    for (final pack in packs) {
      for (final item in pack.items) {
        packedUnits[item.productId] =
            (packedUnits[item.productId] ?? 0) + item.quantity * pack.units;
      }
    }

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

    if (!mounted || seq != _loadSeq) return;
    // Los +/− aún no guardados se mantienen sobre los datos recién leídos
    final products = [
      for (final p in fresh)
        _pendingStock.containsKey(p.id)
            ? p.copyWith(units: p.units + _pendingStock[p.id]!)
            : p,
    ];
    AppDrawer.catalogEmpty.value = products.isEmpty;
    setState(() {
      _products = products;
      _promotionsMap = promoMap;
      _categoryNames = {for (final c in categories) c.id: c.name};
      // Si se borró la categoría filtrada, se quita el filtro
      if (!_categoryNames.containsKey(_categoryFilter)) _categoryFilter = null;
      _comboNames = {
        for (final combo in combos)
          for (final id in combo.productIds) id: combo.name,
      };
      _packedUnits = packedUnits;
      _selected.retainAll({for (final p in products) p.id});
      _isLoading = false;
    });
    if (!_guideTried) {
      _guideTried = true;
      CoachGuide.showOnce(context, 'inventory', _guideSteps);
    }
  }

  /// Pasos de la guía: con el inventario vacío invita a crear el primero.
  List<CoachStep> _guideSteps() {
    final l10n = context.l10n;
    if (_products.isEmpty) {
      return [
        CoachStep(
          target: _fabKey,
          title: l10n.coachInventoryEmptyTitle,
          text: l10n.coachInventoryEmptyText,
        ),
      ];
    }
    return [
      CoachStep(target: _fabKey, text: l10n.coachInventoryAdd),
      CoachStep(target: _filtersKey, text: l10n.coachInventoryFilters),
      CoachStep(target: _selectKey, text: l10n.coachInventorySelect),
    ];
  }

  // ------------------------------------------------------------------
  // Edición múltiple
  // ------------------------------------------------------------------

  void _startSelecting([Product? first]) => setState(() {
    _selecting = true;
    if (first?.id != null) _selected.add(first!.id!);
  });

  void _exitSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  void _toggleSelected(Product product) {
    final id = product.id;
    if (id == null) return;
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _selectAll(List<Product> visible, bool select) => setState(() {
    final ids = {for (final p in visible) ?p.id};
    select ? _selected.addAll(ids) : _selected.removeAll(ids);
  });

  List<Product> get _selectedProducts => [
    for (final p in _products)
      if (_selected.contains(p.id)) p,
  ];

  Future<void> _bulkEdit() async {
    final products = _selectedProducts;
    if (products.isEmpty) return;
    final edit = await showBulkEditSheet(
      context,
      count: products.length,
      promotions: _promotionsMap.values.toList(),
    );
    if (edit == null || !mounted) return;
    final changed = await _productRepository.updateMany(edit, products);
    if (!mounted) return;
    _exitSelecting();
    await _loadProducts();
    if (mounted) {
      AppAlerts.showSuccess(context, context.l10n.bulkUpdated(changed));
    }
  }

  Future<void> _bulkDelete() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    var answered = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.bulkDeleteTitle(ids.length)),
        content: Text(dialogContext.l10n.bulkDeleteBody),
        actions: [
          TextButton(
            onPressed: () {
              if (answered) return;
              answered = true;
              Navigator.pop(dialogContext, false);
            },
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () {
              if (answered) return;
              answered = true;
              Navigator.pop(dialogContext, true);
            },
            child: Text(dialogContext.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final id in ids) {
      _discardPendingStock(id);
    }
    final deleted = await _productRepository.deleteMany(ids);
    if (!mounted) return;
    _exitSelecting();
    await _loadProducts();
    if (mounted) {
      AppAlerts.showWarning(context, context.l10n.bulkDeleted(deleted));
    }
  }

  void _updateStockQuickly(Product product, int amountChange) {
    final productId = product.id!;
    final prodIndex = _products.indexWhere((p) => p.id == productId);
    if (prodIndex == -1) return;

    final currentProduct = _products[prodIndex];
    final newUnits = currentProduct.units + amountChange;
    if (newUnits < 0) return;

    _pendingStock[productId] = (_pendingStock[productId] ?? 0) + amountChange;
    setState(() {
      _products[prodIndex] = currentProduct.copyWith(units: newUnits);
    });

    _debounceTimers[productId]?.cancel();
    _debounceTimers[productId] = Timer(
      const Duration(milliseconds: 600),
      () => _flushStock(productId),
    );
  }

  /// Guarda los +/− pendientes de un producto como una suma atómica.
  Future<void> _flushStock(int productId) async {
    _debounceTimers.remove(productId)?.cancel();
    final delta = _pendingStock.remove(productId) ?? 0;
    if (delta != 0) await _productRepository.addUnits(productId, delta);
    if (mounted) _loadProducts();
  }

  /// Antes de escribir un stock exacto se descartan los +/− pendientes (el
  /// valor escrito ya los incluye: es lo que se veía en pantalla).
  void _discardPendingStock(int productId) {
    _debounceTimers.remove(productId)?.cancel();
    _pendingStock.remove(productId);
  }

  // --- Filtros, orden y vista (tarjetas en móvil / tabla en tablet) ---

  void _onSort(InventorySort sort) {
    setState(() {
      if (_sort == sort) {
        _sortAscending = !_sortAscending;
      } else {
        _sort = sort;
        _sortAscending = true;
      }
    });
  }

  void _resetSort() => setState(() {
    _sort = null;
    _sortAscending = true;
  });

  Widget _buildProductList(List<Product> products) {
    final editor = _productEditor;
    final actions = InventoryProductActions(
      onEditProduct: (product) =>
          editor.showProductFormDialog(context, productToEdit: product),
      onDeleteProduct: (product) =>
          editor.showDeleteConfirmation(context, product),
      onEditImage: (product) => editor.editSingleImage(context, product),
      onEditField: (product, field) =>
          editor.showProductFieldDialog(context, product, field),
      onStockChange: _updateStockQuickly,
      onEditPromotion: (product) =>
          editor.showPromotionSelectDialog(context, product),
      onEditCategory: (product) => editor.editCategory(context, product),
    );
    return ListView.builder(
      // Hueco para el botón ＋ y la barra de navegación
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        96 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return InventoryProductCard(
          product: product,
          promotion: product.promotionId == null
              ? null
              : _promotionsMap[product.promotionId],
          actions: actions,
          comboName: _comboNames[product.id],
          packedUnits: _packedUnits[product.id] ?? 0,
          categoryName: _categoryNames[product.categoryId],
          selectionMode: _selecting,
          selected: _selected.contains(product.id),
          onSelectChanged: () => _toggleSelected(product),
          onLongPress: () => _startSelecting(product),
        );
      },
    );
  }

  Widget _buildProductTable(
    List<Product> products,
    BoxConstraints constraints,
  ) {
    final editor = _productEditor;
    return SingleChildScrollView(
      controller: _verticalScrollController,
      padding: const EdgeInsets.only(bottom: 96),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        child: InventoryProductsTable(
          verticalController: _verticalScrollController,
          minWidth: constraints.maxWidth,
          products: products,
          promotions: _promotionsMap,
          comboNames: _comboNames,
          packedUnits: _packedUnits,
          categoryNames: _categoryNames,
          onEditCategory: (product) => editor.editCategory(context, product),
          onEditProduct: (product) =>
              editor.showProductFormDialog(context, productToEdit: product),
          onDeleteProduct: (product) =>
              editor.showDeleteConfirmation(context, product),
          onEditImage: (product) => editor.editSingleImage(context, product),
          onEditField: (product, field) =>
              editor.showProductFieldDialog(context, product, field),
          onStockChange: _updateStockQuickly,
          onEditPromotion: (product) =>
              editor.showPromotionSelectDialog(context, product),
          sort: _sort,
          ascending: _sortAscending,
          onSort: _onSort,
          onResetSort: _resetSort,
          selectionMode: _selecting,
          selectedIds: _selected,
          onSelectChanged: (product, _) => _toggleSelected(product),
          onSelectAll: (select) => _selectAll(products, select),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = InventorySummary.of(_products);
    final filteredProducts = InventoryView.apply(
      _products,
      query: _searchQuery,
      filter: _filter,
      validPromotionIds: _promotionsMap.keys.toSet(),
      sort: _sort,
      ascending: _sortAscending,
      categoryId: _categoryFilter,
    );

    return PopScope(
      // Con la selección activa, "atrás" la cierra en vez de salir
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelecting();
      },
      child: Listener(
        onPointerDown: (event) {
          _startX = event.position.dx;
          _startY = event.position.dy;
        },
        onPointerMove: (event) {
          if (_startX == null || _startY == null) return;
          final dx = event.position.dx - _startX!;
          final dy = event.position.dy - _startY!;

          final bool isAtStartOfTable =
              !_horizontalScrollController.hasClients ||
              _horizontalScrollController.offset <= 0;

          if (isAtStartOfTable && dx > 50 && dy.abs() < 30) {
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
          appBar: _selecting
              ? AppBar(
                  leading: IconButton(
                    tooltip: context.l10n.inventoryExitSelection,
                    icon: const Icon(Icons.close),
                    onPressed: _exitSelecting,
                  ),
                  title: Text(
                    context.l10n.inventorySelectedCount(_selected.length),
                  ),
                  actions: [
                    IconButton(
                      tooltip: context.l10n.inventorySelectAll,
                      icon: const Icon(Icons.select_all),
                      onPressed: () => _selectAll(filteredProducts, true),
                    ),
                    IconButton(
                      tooltip: context.l10n.inventoryBulkEdit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _selected.isEmpty ? null : _bulkEdit,
                    ),
                    IconButton(
                      tooltip: context.l10n.inventoryBulkDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: _selected.isEmpty
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _selected.isEmpty ? null : _bulkDelete,
                    ),
                  ],
                )
              : AppBar(
                  title: Text(context.l10n.inventoryTitle),
                  actions: [
                    if (_products.isNotEmpty)
                      IconButton(
                        key: _selectKey,
                        tooltip: context.l10n.inventorySelectTooltip,
                        icon: const Icon(Icons.checklist),
                        onPressed: _startSelecting,
                      ),
                    IconButton(
                      tooltip: context.l10n.coachHelpTooltip,
                      icon: const Icon(Icons.help_outline),
                      onPressed: () =>
                          CoachGuide.replay(context, 'inventory', _guideSteps),
                    ),
                    IconButton(
                      tooltip: context.l10n.categoriesTitle,
                      icon: const Icon(Icons.sell_outlined),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        );
                        // Al volver: nombres, filtros y asignaciones al día
                        if (mounted) _loadProducts();
                      },
                    ),
                  ],
                ),
          drawer: appDrawer(context),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: context.l10n.searchProduct,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          fillColor: Theme.of(context).cardColor,
                        ),
                      ),
                    ),
                    if (_products.isNotEmpty)
                      KeyedSubtree(
                        key: _filtersKey,
                        child: InventoryFiltersBar(
                          summary: summary,
                          filter: _filter,
                          onFilterChanged: (filter) =>
                              setState(() => _filter = filter),
                          categoryNames: _categoryNames,
                          categoryFilter: _categoryFilter,
                          onCategoryChanged: (categoryId) =>
                              setState(() => _categoryFilter = categoryId),
                          sort: _sort,
                          ascending: _sortAscending,
                          onSort: _onSort,
                          onResetSort: _resetSort,
                          isNarrow:
                              MediaQuery.sizeOf(context).width < _tableMinWidth,
                        ),
                      ),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: _products.isEmpty
                                  ? context.l10n.inventoryEmpty
                                  : context.l10n.productsNotFound,
                              action: _products.isEmpty
                                  ? FilledButton.icon(
                                      onPressed: () => _productEditor
                                          .showProductFormDialog(context),
                                      icon: const Icon(Icons.add),
                                      label: Text(
                                        context.l10n.inventoryAddFirst,
                                      ),
                                    )
                                  : null,
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) =>
                                  constraints.maxWidth >= _tableMinWidth
                                  ? _buildProductTable(
                                      filteredProducts,
                                      constraints,
                                    )
                                  : _buildProductList(filteredProducts),
                            ),
                    ),
                  ],
                ),
          floatingActionButton: _selecting
              ? null
              : FloatingActionButton(
                  key: _fabKey,
                  onPressed: () =>
                      _productEditor.showProductFormDialog(context),
                  child: const Icon(Icons.add),
                ),
        ),
      ),
    );
  }
}
