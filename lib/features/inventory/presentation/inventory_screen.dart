import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

// Widgets modularizados
import 'widgets/inventory_products_table.dart';
import 'widgets/product_form_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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
  bool _isLoading = true;

  String _searchQuery = '';

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

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productRepository.getProducts();
    final promotions = await _promotionRepository.getPromotions();

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

    if (!mounted) return;
    setState(() {
      _products = products;
      _promotionsMap = promoMap;
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
  }) {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.editFieldTitle(title)),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: context.l10n.newValue,
              border: OutlineInputBorder(),
            ),
            autofocus: true,
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
            if (context.mounted) {
              Navigator.pop(context);
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

    switch (field) {
      case InventoryProductField.name:
        title = context.l10n.fieldName;
        initialValue = product.name;
        keyboardType = TextInputType.text;
      case InventoryProductField.units:
        title = context.l10n.fieldUnits;
        initialValue = product.units.toString();
        keyboardType = TextInputType.number;
      case InventoryProductField.price:
        title = context.l10n.fieldSalePrice;
        initialValue = product.price.toString();
        keyboardType = const TextInputType.numberWithOptions(decimal: true);
      case InventoryProductField.cost:
        title = context.l10n.fieldAcquisitionCost;
        initialValue = product.cost.toString();
        keyboardType = const TextInputType.numberWithOptions(decimal: true);
    }

    _showEditSingleFieldDialog(
      product: product,
      title: title,
      initialValue: initialValue,
      keyboardType: keyboardType,
      onSave: (value) => _saveProductField(product, field, value),
    );
  }

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
        final units = int.tryParse(value);
        if (units == null || units < 0) return;
        updatedProduct = _toModel(product, units: units);
        successMessage = context.l10n.stockUpdated;
      case InventoryProductField.price:
        final price = double.tryParse(value.replaceAll(',', '.'));
        if (price == null || price < 0) return;
        updatedProduct = _toModel(product, price: price);
        successMessage = context.l10n.salePriceUpdated;
      case InventoryProductField.cost:
        final cost = double.tryParse(value.replaceAll(',', '.'));
        if (cost == null || cost < 0) return;
        updatedProduct = _toModel(product, cost: cost);
        successMessage = context.l10n.costUpdated;
    }

    await _productRepository.updateProduct(updatedProduct);
    if (!mounted) return;

    Navigator.pop(context);
    _loadProducts();
    AppAlerts.showSuccess(context, successMessage);
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
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
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchProduct,
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              _products.isEmpty
                                  ? context.l10n.inventoryEmpty
                                  : context.l10n.productsNotFound,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _horizontalScrollController,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: InventoryProductsTable(
                                      products: filteredProducts,
                                      promotions: _promotionsMap,
                                      onEditProduct: (product) =>
                                          _showProductFormDialog(
                                            productToEdit: product,
                                          ),
                                      onDeleteProduct: (product) =>
                                          _showDeleteConfirmation(product.id!),
                                      onEditImage: _editSingleImage,
                                      onEditField: _showProductFieldDialog,
                                      onStockChange: _updateStockQuickly,
                                      onEditPromotion:
                                          _showPromotionSelectDialog,
                                    ),
                                  ),
                                ),
                              );
                            },
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
