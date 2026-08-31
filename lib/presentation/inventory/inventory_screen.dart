import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_utils;

import '../shared/app_drawer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/promotion.dart';
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

  // Controlador para detectar si la tabla está al principio o desplazada
  final ScrollController _horizontalScrollController = ScrollController();

  double? _startX;
  double? _startY;

  List<Product> _products = [];
  Map<int, Promotion> _promotionsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _repository.getProducts();
    final promotions = await _repository.getPromotions();

    final Map<int, Promotion> promoMap = {for (var p in promotions) p.id!: p};

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

  Future<void> _updateStockQuickly(Product product, int amountChange) async {
    final newUnits = product.units + amountChange;
    if (newUnits < 0) return;

    final updatedProduct = product.copyWith(units: newUnits);
    await _repository.updateProduct(updatedProduct);
    _loadProducts();
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

      final updatedProduct = product.copyWith(imagePath: permanentFile.path);
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

                      final savedProduct = Product(
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
            color: textColor,
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

        // Verificamos si la tabla horizontal está al principio (offset <= 0).
        // Si está al principio y arrastras a la derecha, abrimos el cajón.
        // Si la tabla está desplazada hacia la derecha, el gesto se lo lleva la tabla para hacer scroll.
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
            ? const Center(child: Text('No hay productos en el inventario.'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _horizontalScrollController, // <-- Vinculamos el controlador de scroll
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Acciones')),
                            DataColumn(label: Text('Foto')),
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Unidades')),
                            DataColumn(label: Text('Precio')),
                            DataColumn(label: Text('Coste')),
                            DataColumn(label: Text('Promoción')),
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
                                    child: Container(
                                      padding: const EdgeInsets.all(2.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor
                                              .withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: product.imagePath != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.file(
                                                File(product.imagePath!),
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: Icon(
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
                                            product.copyWith(name: value),
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.orange,
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
                                                product.copyWith(
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
                                            product.copyWith(price: newPrice),
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
                                            product.copyWith(cost: newCost),
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
                                        : Colors.grey,
                                    bold: hasPromo,
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
