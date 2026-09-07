import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../domain/product.dart';
import '../../data/product_model.dart';
import '../../../promotions/domain/promotion.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? productToEdit;
  final Map<int, Promotion> promotionsMap;
  final Future<void> Function(ProductModel product, bool isEditing) onSave;

  const ProductFormDialog({
    super.key,
    this.productToEdit,
    required this.promotionsMap,
    required this.onSave,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late String _name;
  late int _units;
  late double _price;
  late double _cost;
  int? _selectedPromotionId;
  Uint8List? _selectedImageBytes;
  String? _oldImagePath;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _name = p?.name ?? '';
    _units = p?.units ?? 0;
    _price = p?.price ?? 0.0;
    _cost = p?.cost ?? 0.0;
    _selectedPromotionId = p?.promotionId;
    _selectedImageBytes = p?.imageBytes;
    _oldImagePath = p?.imagePath;
  }

  Future<void> _pickAndCompressImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Cámara'),
            onTap: () => _processImage(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galería'),
            onTap: () => _processImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    Navigator.pop(context);
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 400,
        minHeight: 400,
        quality: 70,
      );
      setState(() {
        _selectedImageBytes = compressed.isNotEmpty ? compressed : bytes;
        _oldImagePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final fieldWidth = isLandscape ? 320.0 : 520.0;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      content: SizedBox(
        width: isLandscape ? 760 : 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                // Selector de Imagen
                SizedBox(
                  width: fieldWidth,
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickAndCompressImage,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          image: _selectedImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_selectedImageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : (_oldImagePath != null
                                    ? DecorationImage(
                                        image: FileImage(File(_oldImagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child:
                            _selectedImageBytes == null && _oldImagePath == null
                            ? Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                // Campos de Texto
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _name = v!,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    initialValue: _units.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Unidades en stock',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _units = int.parse(v!),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    initialValue: _price == 0.0 ? '' : _price.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta (€)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                    onSaved: (v) =>
                        _price = double.parse(v!.replaceAll(',', '.')),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    initialValue: _cost == 0.0 ? '' : _cost.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Coste de adquisición (€)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                    onSaved: (v) =>
                        _cost = double.parse(v!.replaceAll(',', '.')),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedPromotionId,
                    decoration: const InputDecoration(
                      labelText: 'Promoción Aplicada',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin promoción'),
                      ),
                      ...widget.promotionsMap.values.map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedPromotionId = v),
                  ),
                ),
              ],
            ),
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
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final productModel = ProductModel(
                id: widget.productToEdit?.id,
                name: _name,
                units: _units,
                price: _price,
                cost: _cost,
                imagePath: _oldImagePath,
                imageBytes: _selectedImageBytes,
                promotionId: _selectedPromotionId,
              );
              await widget.onSave(productModel, isEditing);
            }
          },
          child: Text(isEditing ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
