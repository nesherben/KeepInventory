import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../inventory/domain/product.dart';
import '../../domain/pack.dart';

class PackFormDialog extends StatefulWidget {
  final Pack? existingPack;
  final List<Product> availableProducts;
  final Function(Pack) onSave;

  const PackFormDialog({
    super.key,
    this.existingPack,
    required this.availableProducts,
    required this.onSave,
  });

  @override
  State<PackFormDialog> createState() => _PackFormDialogState();
}

class _PackFormDialogState extends State<PackFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String packName;
  late double packPrice;
  late int packUnits;

  Uint8List? selectedImageBytes;
  String? oldImagePath;

  late Map<Product, int> selectedItems;
  Product? _productToAdd;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    packName = widget.existingPack?.name ?? '';
    packPrice = widget.existingPack?.price ?? 0.0;
    packUnits = widget.existingPack?.units ?? 1;

    selectedImageBytes = widget.existingPack?.imageBytes;
    oldImagePath =
        (widget.existingPack?.imagePath != null &&
            File(widget.existingPack!.imagePath!).existsSync())
        ? widget.existingPack!.imagePath
        : null;

    selectedItems = {};
    if (widget.existingPack != null) {
      for (var item in widget.existingPack!.items) {
        try {
          final prod = widget.availableProducts.firstWhere(
            (p) => p.id == item.productId,
          );
          selectedItems[prod] = item.quantity;
        } catch (_) {}
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
      if (compressed.isNotEmpty) {
        return compressed;
      } else {
        return bytes;
      }
    } catch (e) {
      print("❌ Error comprimiendo la imagen: $e");
      return await file.readAsBytes();
    }
  }

  Future<void> _savePack() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Añade al menos 1 producto al pack usando el desplegable.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    for (var entry in selectedItems.entries) {
      if (entry.value > 0) {
        int previousDeduction = 0;
        if (widget.existingPack != null) {
          final prevItem = widget.existingPack!.items.firstWhere(
            (i) => i.productId == entry.key.id,
            orElse: () => PackItem(productId: 0, productName: '', quantity: 0),
          );
          previousDeduction = prevItem.quantity * widget.existingPack!.units;
        }
        final effectiveAvailable = entry.key.units + previousDeduction;
        if ((entry.value * packUnits) > effectiveAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Stock insuficiente de "${entry.key.name}" para montar $packUnits unidades.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    }

    final packItemsList = selectedItems.entries
        .where((e) => e.value > 0)
        .map(
          (e) => PackItem(
            productId: e.key.id!,
            productName: e.key.name,
            quantity: e.value,
          ),
        )
        .toList();

    final newPack = Pack(
      id: widget.existingPack?.id,
      name: packName,
      price: packPrice,
      units: packUnits,
      imagePath: oldImagePath,
      imageBytes: selectedImageBytes,
      items: packItemsList,
    );

    widget.onSave(newPack);
  }

  Widget _buildImagePickerWidget() {
    return GestureDetector(
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
                  await Future.delayed(const Duration(milliseconds: 200));
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (pickedFile != null) {
                    final bytes = await _compressImage(File(pickedFile.path));
                    setState(() {
                      selectedImageBytes = bytes;
                      oldImagePath = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 200));
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    final bytes = await _compressImage(File(pickedFile.path));
                    setState(() {
                      selectedImageBytes = bytes;
                      oldImagePath = null;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        height: 85,
        width: 85,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          image: selectedImageBytes != null
              ? DecorationImage(
                  image: MemoryImage(selectedImageBytes!),
                  fit: BoxFit.cover,
                )
              : (oldImagePath != null
                    ? DecorationImage(
                        image: FileImage(File(oldImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null),
        ),
        child: (selectedImageBytes == null && oldImagePath == null)
            ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 30)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;

    final availableOptions = widget.availableProducts
        .where((p) => !selectedItems.containsKey(p))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 850 : screenSize.width * 0.90,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min, // 💡 El diálogo se ajustará a sus hijos sin forzar el máximo si no es necesario
              children: [
                // --- TÍTULO FIJO ---
                Text(
                  widget.existingPack == null
                      ? 'Crear Nuevo Pack / Bundle'
                      : 'Modificar Pack',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // --- CONTENIDO FLEXIBLE ---
                Flexible(
                  child: isLandscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 💡 HORIZONTAL IZQUIERDA: Items (Con Scroll propio)
                            Expanded(
                              flex: 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Componentes del Pack:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<Product>(
                                          decoration: const InputDecoration(
                                            hintText: 'Añadir producto...',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                          ),
                                          initialValue: _productToAdd,
                                          isExpanded: true,
                                          items: availableOptions.map((p) {
                                            return DropdownMenuItem(
                                              value: p,
                                              child: Text(
                                                p.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() => _productToAdd = val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: _productToAdd == null
                                            ? null
                                            : () {
                                                setState(() {
                                                  selectedItems[_productToAdd!] =
                                                      1;
                                                  _productToAdd = null;
                                                });
                                              },
                                        child: const Icon(Icons.add, size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // LA LISTA TIENE SU PROPIO SCROLL CON FLEXIBLE
                                  Flexible(
                                    child: selectedItems.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No hay productos en este pack.',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : ListView(
                                            shrinkWrap: true, // Importante para que no expanda hasta el infinito
                                            children: _buildItemsList(
                                              parsedUnits:
                                                  int.tryParse(
                                                    packUnits.toString(),
                                                  ) ??
                                                  1,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(width: 24, thickness: 1),
                            // 💡 HORIZONTAL DERECHA: Campos fijos
                            Expanded(
                              flex: 9,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(child: _buildImagePickerWidget()),
                                    const SizedBox(height: 16),
                                    _buildNameField(),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildPriceField()),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildUnitsField()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 💡 VERTICAL: Campos fijos arriba
                            Center(child: _buildImagePickerWidget()),
                            const SizedBox(height: 16),
                            _buildNameField(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildPriceField()),
                                const SizedBox(width: 10),
                                Expanded(child: _buildUnitsField()),
                              ],
                            ),
                            const Divider(height: 32, thickness: 1),
                            const Text(
                              'Componentes del Pack:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<Product>(
                                    decoration: const InputDecoration(
                                      hintText: 'Añadir producto...',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    initialValue: _productToAdd,
                                    isExpanded: true,
                                    items: availableOptions.map((p) {
                                      return DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _productToAdd = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: _productToAdd == null
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedItems[_productToAdd!] = 1;
                                            _productToAdd = null;
                                          });
                                        },
                                  child: const Icon(Icons.add, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 💡 VERTICAL: SOLO ESTA LISTA HACE SCROLL
                            Flexible(
                              child: selectedItems.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'No hay productos en este pack.',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      shrinkWrap: true,
                                      children: _buildItemsList(
                                        parsedUnits:
                                            int.tryParse(
                                              packUnits.toString(),
                                            ) ??
                                            1,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),

                // --- BOTONES DE ACCIÓN FIJOS ABAJO ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _savePack,
                      child: Text(
                        widget.existingPack == null ? 'Crear Pack' : 'Guardar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS EXTRACTOS PARA EVITAR REPETIR CÓDIGO ---

  Widget _buildNameField() {
    return TextFormField(
      initialValue: packName,
      decoration: const InputDecoration(
        labelText: 'Nombre del Pack',
        isDense: true,
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Requerido' : null,
      onSaved: (value) => packName = value!.trim(),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      initialValue: packPrice > 0 ? packPrice.toString() : '',
      decoration: const InputDecoration(labelText: 'Precio (€)', isDense: true),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Requerido' : null,
      onSaved: (value) =>
          packPrice = double.tryParse(value!.replaceAll(',', '.')) ?? 0.0,
    );
  }

  Widget _buildUnitsField() {
    return TextFormField(
      initialValue: packUnits.toString(),
      decoration: const InputDecoration(
        labelText: 'Stock inicial',
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Requerido' : null,
      onSaved: (value) => packUnits = int.tryParse(value!) ?? 1,
    );
  }

  List<Widget> _buildItemsList({required int parsedUnits}) {
    return selectedItems.keys.map((product) {
      final qtyPerPack = selectedItems[product]!;

      int previousDeduction = 0;
      if (widget.existingPack != null) {
        final prevItem = widget.existingPack!.items.firstWhere(
          (i) => i.productId == product.id,
          orElse: () => PackItem(productId: 0, productName: '', quantity: 0),
        );
        previousDeduction = prevItem.quantity * widget.existingPack!.units;
      }
      final effectiveAvailable = product.units + previousDeduction;
      final neededTotal = qtyPerPack * parsedUnits;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        elevation: 0,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            product.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Almacén: $effectiveAvailable (Req: $neededTotal)',
            style: TextStyle(
              fontSize: 11,
              color: neededTotal > effectiveAvailable
                  ? Colors.red
                  : Colors.grey[700],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.orange,
                  size: 20,
                ),
                onPressed: qtyPerPack > 1
                    ? () => setState(
                        () => selectedItems[product] = qtyPerPack - 1,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                '$qtyPerPack',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                onPressed:
                    ((qtyPerPack + 1) * parsedUnits) <= effectiveAvailable
                    ? () => setState(
                        () => selectedItems[product] = qtyPerPack + 1,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    selectedItems.remove(product);
                  });
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
