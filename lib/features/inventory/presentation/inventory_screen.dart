import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:flutter/services.dart';

import 'widgets/inventory_product_widgets.dart';
import '../domain/inventory_view.dart';

import '../../../core/shared_widgets/app_ui.dart';

import 'package:image_picker/image_picker.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';
import 'package:keepinventory/core/services/image_compression_service.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart'; // 💡 Importante para las alertas en cola

// Imports de la feature INVENTORY
import '../../promotions/data/repositories/promotion_repository_impl.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/product.dart';
import '../data/product_model.dart';
import '../data/datasources/product_local_datasource.dart';

// Imports de la feature PROMOTIONS
import '../../promotions/domain/promotion.dart';
import '../../promotions/data/datasources/promotion_local_datasource.dart';
import '../../promotions/data/datasources/combo_local_datasource.dart';
import '../../promotions/data/repositories/combo_repository_impl.dart';

// Widgets modularizados
import 'widgets/inventory_products_table.dart';
import 'widgets/product_form_dialog.dart';

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

  final ImagePicker _picker = ImagePicker();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  double? _startX;
  double? _startY;

  List<Product> _products = [];
  Map<int, Promotion> _promotionsMap = {};

  /// Nombre del combo de cada producto (informativo).
  Map<int, String> _comboNames = {};
  bool _isLoading = true;

  String _searchQuery = '';
  InventoryFilter _filter = InventoryFilter.all;
  InventorySort? _sort;
  bool _sortAscending = true;

  final Map<int, Timer> _debounceTimers = {};
  final Map<int, Product> _baseProducts = {};

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
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  ProductModel _toModel(
    Product p, {
    String? name,
    int? units,
    double? price,
    double? cost,
    String? imagePath,
    bool clearImagePath = false,
    Uint8List? imageBytes,
    int? promotionId,
    bool clearPromotion = false,
  }) {
    return ProductModel(
      id: p.id,
      name: name ?? p.name,
      units: units ?? p.units,
      price: price ?? p.price,
      cost: cost ?? p.cost,
      imagePath: clearImagePath ? null : (imagePath ?? p.imagePath),
      imageBytes: imageBytes ?? p.imageBytes,
      promotionId: clearPromotion ? null : (promotionId ?? p.promotionId),
    );
  }

  Future<void> _processAndSaveNewImage(
    Product product,
    ImageSource source,
  ) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final compressedBytes = await ImageCompressionService.compressFile(file);

      final updatedProduct = _toModel(
        product,
        imageBytes: compressedBytes,
        clearImagePath: true,
      );
      await _productRepository.updateProduct(updatedProduct);
      _loadProducts();

      if (mounted) {
        AppAlerts.showSuccess(context, context.l10n.photoUpdated);
      }
    }
  }

  /// Recarga los datos. El indicador de carga solo se ve en la primera carga
  /// (`_isLoading` empieza en true): al recargar tras editar no se sustituye
  /// la lista, así se conserva la posición del scroll.
  Future<void> _loadProducts() async {
    final products = await _productRepository.getProducts();
    final promotions = await _promotionRepository.getPromotions();
    final combos = await ComboRepositoryImpl(ComboLocalDatasource())
        .getCombos();

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

    if (!mounted) return;
    setState(() {
      _products = products;
      _promotionsMap = promoMap;
      _comboNames = {
        for (final combo in combos)
          for (final id in combo.productIds) id: combo.name,
      };
      _isLoading = false;
    });
  }

  Future<void> _deleteProduct(int id) async {
    await _productRepository.deleteProduct(id);
    _loadProducts();

    if (mounted) {
      AppAlerts.showWarning(context, context.l10n.productDeleted);
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.deleteProductTitle),
          content: Text(context.l10n.deleteProductConfirm),
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
              onPressed: () {
                Navigator.pop(context);
                _deleteProduct(id);
              },
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }

  void _updateStockQuickly(Product product, int amountChange) {
    final productId = product.id!;
    final prodIndex = _products.indexWhere((p) => p.id == productId);
    if (prodIndex == -1) return;

    final currentProduct = _products[prodIndex];
    final newUnits = currentProduct.units + amountChange;
    if (newUnits < 0) return;

    if (!_baseProducts.containsKey(productId)) {
      _baseProducts[productId] = currentProduct;
    }

    final updatedModel = _toModel(currentProduct, units: newUnits);

    setState(() {
      _products[prodIndex] = updatedModel;
    });

    _debounceTimers[productId]?.cancel();
    _debounceTimers[productId] = Timer(
      const Duration(milliseconds: 600),
      () async {
        final baseProduct = _baseProducts[productId];
        final finalProduct = _products.firstWhere((p) => p.id == productId);

        if (baseProduct != null && baseProduct.units != finalProduct.units) {
          await _productRepository.updateProduct(_toModel(finalProduct));
        }

        _baseProducts.remove(productId);
        _debounceTimers.remove(productId);

        if (mounted) {
          final freshProducts = await _productRepository.getProducts();
          setState(() {
            _products = freshProducts;
          });
        }
      },
    );
  }

  void _showEditSingleFieldDialog({
    required Product product,
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
    required Future<void> Function(String) onSave,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    // Texto seleccionado al abrir: se sobrescribe escribiendo directamente
    final TextEditingController controller =
        TextEditingController(text: initialValue)
          ..selection = TextSelection(
            baseOffset: 0,
            extentOffset: initialValue.length,
          );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.editFieldTitle(title)),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              labelText: context.l10n.newValue,
              suffixText: suffixText,
            ),
            autofocus: true,
            onSubmitted: (value) => onSave(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                await onSave(controller.text);
              },
              child: Text(context.l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _showPromotionSelectDialog(Product product) {
    int? selectedPromotionId = product.promotionId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.selectPromotion),
              content: DropdownButtonFormField<int?>(
                initialValue: selectedPromotionId,
                decoration: InputDecoration(
                  labelText: context.l10n.appliedPromotion,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.l10n.noPromotion),
                  ),
                  ..._promotionsMap.values.map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() => selectedPromotionId = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _productRepository.updateProduct(
                      _toModel(
                        product,
                        promotionId: selectedPromotionId,
                        clearPromotion: selectedPromotionId == null,
                      ),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadProducts();
                      AppAlerts.showSuccess(
                        context,
                        context.l10n.promotionUpdated,
                      );
                    }
                  },
                  child: Text(context.l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editSingleImage(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(context.l10n.takeNewPhoto),
            onTap: () async {
              Navigator.pop(context);
              await _processAndSaveNewImage(product, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(context.l10n.chooseGalleryPhoto),
            onTap: () async {
              Navigator.pop(context);
              await _processAndSaveNewImage(product, ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  void _showProductFormDialog({Product? productToEdit}) {
    showDialog(
      context: context,
      builder: (context) {
        return ProductFormDialog(
          productToEdit: productToEdit,
          promotionsMap: _promotionsMap,
          onSave: (productModel, isEditing) async {
            if (isEditing) {
              await _productRepository.updateProduct(productModel);
            } else {
              await _productRepository.insertProduct(productModel);
            }
            // El diálogo se cierra solo tras guardar
            if (context.mounted) {
              _loadProducts();
              AppAlerts.showSuccess(
                context,
                isEditing
                    ? context.l10n.productUpdated
                    : context.l10n.productCreated,
              );
            }
          },
        );
      },
    );
  }

  void _showProductFieldDialog(Product product, InventoryProductField field) {
    late final String title;
    late final String initialValue;
    late final TextInputType keyboardType;
    List<TextInputFormatter>? formatters;
    String? suffix;

    switch (field) {
      case InventoryProductField.name:
        title = context.l10n.fieldName;
        initialValue = product.name;
        keyboardType = TextInputType.text;
      case InventoryProductField.units:
        title = context.l10n.fieldUnits;
        initialValue = product.units.toString();
        keyboardType = TextInputType.number;
        formatters = AppNumbers.integerInputFormatters;
      case InventoryProductField.price:
        title = context.l10n.fieldSalePrice;
        initialValue = context.amountInput(product.price);
        keyboardType = AppNumbers.decimalKeyboard;
        formatters = AppNumbers.decimalInputFormatters;
        suffix = '€';
      case InventoryProductField.cost:
        title = context.l10n.fieldAcquisitionCost;
        initialValue = context.amountInput(product.cost);
        keyboardType = AppNumbers.decimalKeyboard;
        formatters = AppNumbers.decimalInputFormatters;
        suffix = '€';
    }

    _showEditSingleFieldDialog(
      product: product,
      title: title,
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      suffixText: suffix,
      onSave: (value) => _saveProductField(product, field, value),
    );
  }

  void _showInvalidNumber() =>
      AppAlerts.showError(context, context.l10n.invalidNumber);

  Future<void> _saveProductField(
    Product product,
    InventoryProductField field,
    String value,
  ) async {
    late final ProductModel updatedProduct;
    late final String successMessage;

    switch (field) {
      case InventoryProductField.name:
        if (value.isEmpty) return;
        updatedProduct = _toModel(product, name: value);
        successMessage = context.l10n.nameUpdated;
      case InventoryProductField.units:
        final units = AppNumbers.parseInt(value);
        if (units == null || units < 0) return _showInvalidNumber();
        updatedProduct = _toModel(product, units: units);
        successMessage = context.l10n.stockUpdated;
      case InventoryProductField.price:
        final price = AppNumbers.parseDecimal(value);
        if (price == null || price < 0) return _showInvalidNumber();
        updatedProduct = _toModel(product, price: price);
        successMessage = context.l10n.salePriceUpdated;
      case InventoryProductField.cost:
        final cost = AppNumbers.parseDecimal(value);
        if (cost == null || cost < 0) return _showInvalidNumber();
        updatedProduct = _toModel(product, cost: cost);
        successMessage = context.l10n.costUpdated;
    }

    await _productRepository.updateProduct(updatedProduct);
    if (!mounted) return;

    Navigator.pop(context);
    _loadProducts();
    AppAlerts.showSuccess(context, successMessage);
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

  String _sortLabel(InventorySort sort) => switch (sort) {
    InventorySort.name => context.l10n.inventorySortName,
    InventorySort.units => context.l10n.inventorySortUnits,
    InventorySort.price => context.l10n.inventorySortPrice,
    InventorySort.cost => context.l10n.inventorySortCost,
    InventorySort.margin => context.l10n.inventoryMargin,
  };

  /// Menú de orden para móvil (las tarjetas no tienen cabeceras que tocar).
  /// Comparte estado con la tabla. Elegir el criterio activo invierte el sentido.
  Widget _buildSortButton() {
    final colors = Theme.of(context).colorScheme;
    final active = _sort;
    final arrow = _sortAscending ? Icons.arrow_upward : Icons.arrow_downward;
    const defaultChoice = -1;

    PopupMenuItem<int> option(int value, String label, bool selected) =>
        PopupMenuItem<int>(
          value: value,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: selected
                    ? Icon(
                        value == defaultChoice ? Icons.check : arrow,
                        size: 18,
                        color: colors.primary,
                      )
                    : null,
              ),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? colors.primary : null,
                ),
              ),
            ],
          ),
        );

    return PopupMenuButton<int>(
      tooltip: context.l10n.inventorySortTitle,
      onSelected: (value) => value == defaultChoice
          ? _resetSort()
          : _onSort(InventorySort.values[value]),
      itemBuilder: (context) => [
        option(
          defaultChoice,
          context.l10n.inventorySortDefault,
          active == null,
        ),
        const PopupMenuDivider(),
        for (final sort in InventorySort.values)
          option(sort.index, _sortLabel(sort), active == sort),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 18,
              color: active == null ? colors.onSurfaceVariant : colors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              active == null
                  ? context.l10n.inventorySortTitle
                  : _sortLabel(active),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active == null
                    ? colors.onSurfaceVariant
                    : colors.primary,
              ),
            ),
            if (active != null) ...[
              const SizedBox(width: 2),
              Icon(arrow, size: 14, color: colors.primary),
            ],
          ],
        ),
      ),
    );
  }

  InventoryProductActions get _productActions => InventoryProductActions(
    onEditProduct: (product) => _showProductFormDialog(productToEdit: product),
    onDeleteProduct: (product) => _showDeleteConfirmation(product.id!),
    onEditImage: _editSingleImage,
    onEditField: _showProductFieldDialog,
    onStockChange: _updateStockQuickly,
    onEditPromotion: _showPromotionSelectDialog,
  );

  Widget _buildFilters(InventorySummary summary) {
    final colors = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.sizeOf(context).width < _tableMinWidth;
    Widget chip(InventoryFilter filter, String label, {int? count}) {
      final selected = _filter == filter;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(count == null ? label : '$label ($count)'),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _filter = filter),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              chip(InventoryFilter.all, context.l10n.inventoryFilterAll),
              chip(
                InventoryFilter.lowStock,
                context.l10n.inventoryFilterLow,
                count: summary.lowStock,
              ),
              chip(
                InventoryFilter.outOfStock,
                context.l10n.inventoryFilterOut,
                count: summary.outOfStock,
              ),
              chip(
                InventoryFilter.withPromotion,
                context.l10n.inventoryFilterPromo,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, isNarrow ? 4 : 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.inventorySummary(
                    summary.products.toString(),
                    summary.units.toString(),
                    summary.outOfStock.toString(),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              // En tablet se ordena tocando las cabeceras de la tabla
              if (isNarrow) _buildSortButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return InventoryProductCard(
          product: product,
          promotion: product.promotionId == null
              ? null
              : _promotionsMap[product.promotionId],
          actions: _productActions,
          comboName: _comboNames[product.id],
        );
      },
    );
  }

  Widget _buildProductTable(
    List<Product> products,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: InventoryProductsTable(
            products: products,
            promotions: _promotionsMap,
            comboNames: _comboNames,
            onEditProduct: (product) =>
                _showProductFormDialog(productToEdit: product),
            onDeleteProduct: (product) => _showDeleteConfirmation(product.id!),
            onEditImage: _editSingleImage,
            onEditField: _showProductFieldDialog,
            onStockChange: _updateStockQuickly,
            onEditPromotion: _showPromotionSelectDialog,
            sort: _sort,
            ascending: _sortAscending,
            onSort: _onSort,
            onResetSort: _resetSort,
          ),
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
        appBar: AppBar(title: Text(context.l10n.inventoryTitle)),
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
                  if (_products.isNotEmpty) _buildFilters(summary),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: _products.isEmpty
                                ? context.l10n.inventoryEmpty
                                : context.l10n.productsNotFound,
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
          onPressed: () => _showProductFormDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
