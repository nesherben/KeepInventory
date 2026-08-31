import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_utils;

import '../shared/app_drawer.dart';
import '../../domain/entities/product.dart';
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

  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _repository.getProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    _loadProducts();
  }

  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    int units = 0;
    double price = 0.0;
    double cost = 0.0;
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder es necesario para actualizar la foto dentro del popup
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Producto'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zona para seleccionar imagen
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
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => name = value!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Unidades en stock',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => units = int.parse(value!),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Precio de venta (€)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => price = double.parse(value!),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Coste de adquisición (€)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => cost = double.parse(value!),
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

                      String? savedImagePath;
                      // Si hay imagen, la movemos del temporal al directorio seguro de la app
                      if (selectedImage != null) {
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

                      final newProduct = Product(
                        name: name,
                        units: units,
                        price: price,
                        cost: cost,
                        imagePath: savedImagePath,
                      );

                      await _repository.insertProduct(newProduct);
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadProducts();
                      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Inventario')),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text('No hay productos en el inventario.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Foto')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Unidades')),
                    DataColumn(label: Text('Precio')),
                    DataColumn(label: Text('Coste')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _products.map((product) {
                    return DataRow(
                      cells: [
                        DataCell(
                          product.imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(product.imagePath!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                        ),
                        DataCell(Text(product.name)),
                        DataCell(Text(product.units.toString())),
                        DataCell(Text('${product.price.toStringAsFixed(2)} €')),
                        DataCell(Text('${product.cost.toStringAsFixed(2)} €')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product.id!),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
