import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_utils;

import '../shared/app_drawer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/promotion.dart';
import '../../data/models/product_model.dart';
import '../../data/datasources/local_database_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repository = InventoryRepositoryImpl(LocalDatabaseDatasource());
  final ImagePicker _picker = ImagePicker();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _horizontalScrollController = ScrollController();

  double? _startX;
  double? _startY;

  List<Product> _products = [];
  Map<int, Promotion> _promotionsMap = {};
  bool _isLoading = true;

  // Control de Debounce para ajustes rápidos de stock
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
    super.dispose();
  }

  // Conversor seguro de Product -> ProductModel
  ProductModel _toModel(
    Product p, {
    String? name,
    int? units,
    double? price,
    double? cost,
    String? imagePath,
    int? promotionId,
  }) {
    return ProductModel(
      id: p.id,
      name: name ?? p.name,
      units: units ?? p.units,
      price: price ?? p.price,
      cost: cost ?? p.cost,
      imagePath: imagePath ?? p.imagePath,
      promotionId: promotionId ?? p.promotionId,
    );
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _repository.getProducts();
    final promotions = await _repository.getPromotions();

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

    if (!mounted) return;
    setState(() {
      _products = products;
      _promotionsMap = promoMap;
      _isLoading = false;
    });
  }

  Future<void> _deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    _loadProducts();
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _deleteProduct(id);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- AJUSTE RÁPIDO DE STOCK CON ACTUALIZACIÓN OPTIMISTA Y DEBOUNCE ---
  void _updateStockQuickly(Product product, int amountChange) {
    final productId = product.id!;
    final prodIndex = _products.indexWhere((p) => p.id == productId);
    if (prodIndex == -1) return;

    final currentProduct = _products[prodIndex];
    final newUnits = currentProduct.units + amountChange;
    if (newUnits < 0) return;

    // 1. Guardar estado base antes de la ráfaga de toques
    if (!_baseProducts.containsKey(productId)) {
      _baseProducts[productId] = currentProduct;
    }

    final updatedModel = _toModel(currentProduct, units: newUnits);

    // 2. Actualización instantánea en memoria (0 ms de lag)
    setState(() {
      _products[prodIndex] = updatedModel;
    });

    // 3. Debounce: Espera 600 ms tras la última pulsación para guardar en BD
    _debounceTimers[productId]?.cancel();
    _debounceTimers[productId] = Timer(
      const Duration(milliseconds: 600),
      () async {
        final baseProduct = _baseProducts[productId];
        final finalProduct = _products.firstWhere((p) => p.id == productId);

        if (baseProduct != null && baseProduct.units != finalProduct.units) {
          await _repository.updateProduct(_toModel(finalProduct));
        }

        _baseProducts.remove(productId);
        _debounceTimers.remove(productId);

        if (mounted) {
          final freshProducts = await _repository.getProducts();
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

  Future<void> _processAndSaveNewImage(
    Product product,
    ImageSource source,
  ) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path_utils.basename(pickedFile.path);
      final permanentFile = await File(pickedFile.path)
          .copy('${directory.path}/$fileName');

      final updatedProduct = _toModel(product, imagePath: permanentFile.path);
      await _repository.updateProduct(updatedProduct);
      _loadProducts();
    }
  }

  void _showProductFormDialog({Product? productToEdit}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = productToEdit != null;

    String name = isEditing ? productToEdit.name : '';
    int units = isEditing ? productToEdit.units : 0;
    double price = isEditing ? productToEdit.price : 0.0;
    double cost = isEditing ? productToEdit.cost : 0.0;
    int? selectedPromotionId = isEditing ? productToEdit.promotionId : null;
    File? selectedImage = (isEditing && productToEdit.imagePath != null)
        ? File(productToEdit.imagePath!)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Cámara'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final pickedFile = await _picker.pickImage(
                                      source: ImageSource.camera,
                                    );
                                    if (pickedFile != null) {
                                      setDialogState(
                                        () => selectedImage = File(
                                          pickedFile.path,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galería'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final pickedFile = await _picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (pickedFile != null) {
                                      setDialogState(
                                        () => selectedImage = File(
                                          pickedFile.path,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            image: selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: selectedImage == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => name = value!,
                      ),
                      TextFormField(
                        initialValue: units.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Unidades en stock',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => units = int.parse(value!),
                      ),
                      TextFormField(
                        initialValue: price == 0.0 ? '' : price.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Precio de venta (€)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) =>
                            price = double.parse(value!.replaceAll(',', '.')),
                      ),
                      TextFormField(
                        initialValue: cost == 0.0 ? '' : cost.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Coste de adquisición (€)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) =>
                            cost = double.parse(value!.replaceAll(',', '.')),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedPromotionId,
                        decoration: const InputDecoration(
                          labelText: 'Promoción Aplicada',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sin promoción'),
                          ),
                          ..._promotionsMap.values.map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedPromotionId = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      String? savedImagePath = isEditing
                          ? productToEdit.imagePath
                          : null;

                      if (selectedImage != null &&
                          selectedImage!.path != productToEdit?.imagePath) {
                        final directory =
                            await getApplicationDocumentsDirectory();
                        final fileName = path_utils.basename(
                          selectedImage!.path,
                        );
                        final permanentFile = await selectedImage!.copy(
                          '${directory.path}/$fileName',
                        );
                        savedImagePath = permanentFile.path;
                      }

                      final savedProduct = ProductModel(
                        id: isEditing ? productToEdit.id : null,
                        name: name,
                        units: units,
                        price: price,
                        cost: cost,
                        imagePath: savedImagePath,
                        promotionId: selectedPromotionId,
                      );

                      if (isEditing) {
                        await _repository.updateProduct(savedProduct);
                      } else {
                        await _repository.insertProduct(savedProduct);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadProducts();
                      }
                    }
                  },
                  child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildClickableCell(
    String text,
    VoidCallback onTap, {
    bool bold = false,
    Color? textColor,
    int maxLength = 20,
  }) {
    final displayText = text.length > maxLength
        ? '${text.substring(0, maxLength - 3)}...'
        : text;

    return Tooltip(
      message: text.length > maxLength ? text : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 15 : 14,
              color: textColor ?? Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            : _products.isEmpty
            ? const Center(
                child: Text(
                  'No hay productos en el inventario.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
                            Theme.of(context).primaryColor
                                .withValues(alpha: 0.08),
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
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
                          rows: _products.map((product) {
                            final hasPromo =
                                product.promotionId != null &&
                                _promotionsMap.containsKey(product.promotionId);
                            final promoName = hasPromo
                                ? _promotionsMap[product.promotionId]!.name
                                : 'Sin promoción';

                            return DataRow(
                              cells: [
                                DataCell(
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.grey,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showProductFormDialog(
                                          productToEdit: product,
                                        );
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(product.id!);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Editar todo'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Eliminar'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  InkWell(
                                    onTap: () => _editSingleImage(product),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(2.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor
                                              .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: product.imagePath != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.file(
                                                File(product.imagePath!),
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.add_a_photo,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _buildClickableCell(
                                    product.name,
                                    () => _showEditSingleFieldDialog(
                                      product: product,
                                      title: 'Nombre',
                                      initialValue: product.name,
                                      keyboardType: TextInputType.text,
                                      onSave: (value) async {
                                        if (value.isNotEmpty) {
                                          await _repository.updateProduct(
                                            _toModel(product, name: value),
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            _loadProducts();
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
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.orange,
                                          size: 22,
                                        ),
                                        onPressed: product.units > 0
                                            ? () => _updateStockQuickly(
                                                product,
                                                -1,
                                              )
                                            : null,
                                      ),
                                      _buildClickableCell(
                                        product.units.toString(),
                                        () => _showEditSingleFieldDialog(
                                          product: product,
                                          title: 'Unidades',
                                          initialValue: product.units
                                              .toString(),
                                          keyboardType: TextInputType.number,
                                          onSave: (value) async {
                                            final newUnits = int.tryParse(
                                              value,
                                            );
                                            if (newUnits != null &&
                                                newUnits >= 0) {
                                              await _repository.updateProduct(
                                                _toModel(
                                                  product,
                                                  units: newUnits,
                                                ),
                                              );
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                _loadProducts();
                                              }
                                            }
                                          },
                                        ),
                                        bold: true,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.green,
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _updateStockQuickly(product, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  _buildClickableCell(
                                    '${product.price.toStringAsFixed(2)} €',
                                    () => _showEditSingleFieldDialog(
                                      product: product,
                                      title: 'Precio de venta',
                                      initialValue: product.price.toString(),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      onSave: (value) async {
                                        final newPrice = double.tryParse(
                                          value.replaceAll(',', '.'),
                                        );
                                        if (newPrice != null && newPrice >= 0) {
                                          await _repository.updateProduct(
                                            _toModel(product, price: newPrice),
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            _loadProducts();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _buildClickableCell(
                                    '${product.cost.toStringAsFixed(2)} €',
                                    () => _showEditSingleFieldDialog(
                                      product: product,
                                      title: 'Coste de adquisición',
                                      initialValue: product.cost.toString(),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      onSave: (value) async {
                                        final newCost = double.tryParse(
                                          value.replaceAll(',', '.'),
                                        );
                                        if (newCost != null && newCost >= 0) {
                                          await _repository.updateProduct(
                                            _toModel(product, cost: newCost),
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            _loadProducts();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _buildClickableCell(
                                    promoName,
                                    () => _showProductFormDialog(
                                      productToEdit: product,
                                    ),
                                    textColor: hasPromo
                                        ? Colors.amber.shade900
                                        : Colors.grey.shade600,
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showProductFormDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
