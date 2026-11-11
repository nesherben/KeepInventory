import 'categories_screen.dart';
import '../data/datasources/category_local_datasource.dart';
import '../data/repositories/category_repository_impl.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/inventory_product_widgets.dart';
import 'widgets/inventory_filters_bar.dart';
import '../domain/inventory_view.dart';

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
      _isLoading = false;
    });
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
          editor.showDeleteConfirmation(context, product.id!),
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
                editor.showDeleteConfirmation(context, product.id!),
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

    return Listener(
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
        appBar: AppBar(
          title: Text(context.l10n.inventoryTitle),
          actions: [
            IconButton(
              tooltip: context.l10n.categoriesTitle,
              icon: const Icon(Icons.sell_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
                // Al volver: nombres, filtros y asignaciones al día
                if (mounted) _loadProducts();
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
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
                    InventoryFiltersBar(
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
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: _products.isEmpty
                                ? context.l10n.inventoryEmpty
                                : context.l10n.productsNotFound,
                            action: _products.isEmpty
                                ? FilledButton.icon(
                                    onPressed: () =>
                                        _productEditor.showProductFormDialog(
                                          context,
                                        ),
                                    icon: const Icon(Icons.add),
                                    label: Text(context.l10n.inventoryAddFirst),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _productEditor.showProductFormDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
