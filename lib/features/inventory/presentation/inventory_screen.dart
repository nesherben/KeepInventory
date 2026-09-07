import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart'; // 💡 Importante para las alertas en cola
import '../../../../core/theme/app_colors.dart';

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
import 'widgets/inventory_table_cell.dart';
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
      final compressedBytes = await _compressImage(file);

      if (compressedBytes != null) {
        final updatedProduct = _toModel(
          product,
          imageBytes: compressedBytes,
          clearImagePath: true,
        );
        await _productRepository.updateProduct(updatedProduct);
        _loadProducts();

        if (mounted) {
          AppAlerts.showSuccess(context, '📸 ¡Foto actualizada con éxito!');
        }
      }
    }
  }

  Future<Uint8List?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 400,
        minHeight: 400,
        quality: 70,
      );
      return compressed.isNotEmpty ? compressed : bytes;
    } catch (e) {
      print("❌ Error crítico en el compresor: $e");
      return await file.readAsBytes();
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
      AppAlerts.showWarning(context, '🗑️ Producto eliminado permanentemente.');
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este producto de forma permanente?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
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
              child: const Text('Eliminar'),
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
          title: Text('Editar $title'),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              labelText: 'Nuevo valor',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await onSave(controller.text);
              },
              child: const Text('Guardar'),
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
              title: const Text('Seleccionar Promoción'),
              content: DropdownButtonFormField<int?>(
                initialValue: selectedPromotionId,
                decoration: const InputDecoration(
                  labelText: 'Promoción Aplicada',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin promoción'),
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
                  child: const Text('Cancelar'),
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
                        '🏷️ Promoción actualizada.',
                      );
                    }
                  },
                  child: const Text('Guardar'),
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
            title: const Text('Tomar nueva foto'),
            onTap: () async {
              Navigator.pop(context);
              await _processAndSaveNewImage(product, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
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
    final isEditing = productToEdit != null;
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
                    ? '✨ ¡Producto actualizado con éxito!'
                    : '🎉 ¡Producto creado con éxito!',
              );
            }
          },
        );
      },
    );
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
        appBar: AppBar(title: const Text('Gestión de Inventario')),
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
                        hintText: 'Buscar producto por nombre...',
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
                                  ? 'No hay productos en el inventario.'
                                  : 'No se encontraron productos con ese nombre.',
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
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.08),
                                      ),
                                      headingTextStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 65,
                                      horizontalMargin: 16,
                                      columnSpacing: 24,
                                      columns: const [
                                        DataColumn(label: Text('ACCIONES')),
                                        DataColumn(label: Text('FOTO')),
                                        DataColumn(label: Text('NOMBRE')),
                                        DataColumn(label: Text('UNIDADES')),
                                        DataColumn(label: Text('PRECIO')),
                                        DataColumn(label: Text('COSTE')),
                                        DataColumn(label: Text('PROMOCIÓN')),
                                      ],
                                      rows: filteredProducts.map((product) {
                                        final hasPromo =
                                            product.promotionId != null &&
                                            _promotionsMap.containsKey(
                                              product.promotionId,
                                            );
                                        final promoName = hasPromo
                                            ? _promotionsMap[product
                                                      .promotionId]!
                                                  .name
                                            : 'Sin promoción';

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showProductFormDialog(
                                                      productToEdit: product,
                                                    );
                                                  } else if (value ==
                                                      'delete') {
                                                    _showDeleteConfirmation(
                                                      product.id!,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.edit,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Text(
                                                          'Editar todo',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Text('Eliminar'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              InkWell(
                                                onTap: () =>
                                                    _editSingleImage(product),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      width: 1.5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child:
                                                      (product.imageBytes !=
                                                              null &&
                                                          product
                                                              .imageBytes!
                                                              .isNotEmpty)
                                                      ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          child: Image.memory(
                                                            product.imageBytes!,
                                                            fit: BoxFit.cover,
                                                            width: 42,
                                                            height: 42,
                                                          ),
                                                        )
                                                      : (product.imagePath !=
                                                                null &&
                                                            product
                                                                .imagePath!
                                                                .isNotEmpty)
                                                      ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          child: Image.file(
                                                            File(
                                                              product
                                                                  .imagePath!,
                                                            ),
                                                            fit: BoxFit.cover,
                                                            width: 42,
                                                            height: 42,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return Icon(
                                                                    Icons
                                                                        .image_not_supported_outlined,
                                                                    color: Theme.of(
                                                                      context,
                                                                    ).colorScheme.onSurfaceVariant,
                                                                    size: 30,
                                                                  );
                                                                },
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 42,
                                                          height: 42,
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .surfaceContainerHighest,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Icon(
                                                            Icons.add_a_photo,
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            size: 20,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              InventoryTableCell(
                                                text: product.name,
                                                onTap: () =>
                                                    _showEditSingleFieldDialog(
                                                      product: product,
                                                      title: 'Nombre',
                                                      initialValue:
                                                          product.name,
                                                      keyboardType:
                                                          TextInputType.text,
                                                      onSave: (value) async {
                                                        if (value.isNotEmpty) {
                                                          await _productRepository
                                                              .updateProduct(
                                                                _toModel(
                                                                  product,
                                                                  name: value,
                                                                ),
                                                              );
                                                          if (context.mounted) {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _loadProducts();
                                                            AppAlerts.showSuccess(
                                                              context,
                                                              '✏️ Nombre actualizado.',
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                maxLength: 20,
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                      color: AppColors.warning,
                                                      size: 22,
                                                    ),
                                                    onPressed: product.units > 0
                                                        ? () =>
                                                              _updateStockQuickly(
                                                                product,
                                                                -1,
                                                              )
                                                        : null,
                                                  ),
                                                  InventoryTableCell(
                                                    text: product.units
                                                        .toString(),
                                                    onTap: () => _showEditSingleFieldDialog(
                                                      product: product,
                                                      title: 'Unidades',
                                                      initialValue: product
                                                          .units
                                                          .toString(),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onSave: (value) async {
                                                        final newUnits =
                                                            int.tryParse(value);
                                                        if (newUnits != null &&
                                                            newUnits >= 0) {
                                                          await _productRepository
                                                              .updateProduct(
                                                                _toModel(
                                                                  product,
                                                                  units:
                                                                      newUnits,
                                                                ),
                                                              );
                                                          if (context.mounted) {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _loadProducts();
                                                            AppAlerts.showSuccess(
                                                              context,
                                                              '📦 Stock actualizado.',
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                    bold: true,
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.add_circle_outline,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiary,
                                                      size: 22,
                                                    ),
                                                    onPressed: () =>
                                                        _updateStockQuickly(
                                                          product,
                                                          1,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              InventoryTableCell(
                                                text:
                                                    '${product.price.toStringAsFixed(2)} €',
                                                onTap: () => _showEditSingleFieldDialog(
                                                  product: product,
                                                  title: 'Precio de venta',
                                                  initialValue: product.price
                                                      .toString(),
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  onSave: (value) async {
                                                    final newPrice =
                                                        double.tryParse(
                                                          value.replaceAll(
                                                            ',',
                                                            '.',
                                                          ),
                                                        );
                                                    if (newPrice != null &&
                                                        newPrice >= 0) {
                                                      await _productRepository
                                                          .updateProduct(
                                                            _toModel(
                                                              product,
                                                              price: newPrice,
                                                            ),
                                                          );
                                                      if (context.mounted) {
                                                        Navigator.pop(context);
                                                        _loadProducts();
                                                        AppAlerts.showSuccess(
                                                          context,
                                                          '💰 Precio de venta actualizado.',
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              InventoryTableCell(
                                                text:
                                                    '${product.cost.toStringAsFixed(2)} €',
                                                onTap: () => _showEditSingleFieldDialog(
                                                  product: product,
                                                  title: 'Coste de adquisición',
                                                  initialValue: product.cost
                                                      .toString(),
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  onSave: (value) async {
                                                    final newCost =
                                                        double.tryParse(
                                                          value.replaceAll(
                                                            ',',
                                                            '.',
                                                          ),
                                                        );
                                                    if (newCost != null &&
                                                        newCost >= 0) {
                                                      await _productRepository
                                                          .updateProduct(
                                                            _toModel(
                                                              product,
                                                              cost: newCost,
                                                            ),
                                                          );
                                                      if (context.mounted) {
                                                        Navigator.pop(context);
                                                        _loadProducts();
                                                        AppAlerts.showSuccess(
                                                          context,
                                                          '📉 Coste actualizado.',
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              InventoryTableCell(
                                                text: promoName,
                                                onTap: () =>
                                                    _showPromotionSelectDialog(
                                                      product,
                                                    ),
                                                textColor: hasPromo
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                bold: hasPromo,
                                                maxLength: 18,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
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
