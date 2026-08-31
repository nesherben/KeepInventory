import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_utils;

import '../shared/app_drawer.dart';
import '../../domain/entities/pack.dart';
import '../../data/models/product_model.dart';
import '../../data/datasources/local_database_datasource.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  final LocalDatabaseDatasource _datasource = LocalDatabaseDatasource();
  final ImagePicker _picker = ImagePicker();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double? _startX;
  double? _startY;

  bool _isLoading = true;
  List<Pack> _packs = [];
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final packs = await _datasource.getPacks();
    final products = await _datasource.getProducts();
    setState(() {
      _packs = packs;
      _products = products;
      _isLoading = false;
    });
  }

  // --- AJUSTE RÁPIDO DE UNIDADES (+1 / -1) DIRECTO EN LA TARJETA ---
  Future<void> _quickAdjustStock(Pack pack, int delta) async {
    if (delta < 0) {
      if (pack.units <= 0) return;

      final updatedPack = Pack(
        id: pack.id,
        name: pack.name,
        price: pack.price,
        units: pack.units - 1,
        imagePath: pack.imagePath,
        items: pack.items,
      );

      await _datasource.updatePack(pack, updatedPack);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '1 unidad de "${pack.name}" desmontada. Componentes devueltos al almacén.',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else if (delta > 0) {
      // 1. Validar que hay stock de todos los componentes en el almacén
      for (var item in pack.items) {
        final productInStock = _products.cast<ProductModel?>().firstWhere(
          (p) => p?.id == item.productId,
          orElse: () => null,
        );

        if (productInStock == null || productInStock.units < item.quantity) {
          final missingQty = item.quantity - (productInStock?.units ?? 0);
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Falta stock de "${item.productName}" (necesitas $missingQty uds más en almacén).',
                ),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      // 2. Incrementar 1 unidad y recalcular stock en BD
      final updatedPack = Pack(
        id: pack.id,
        name: pack.name,
        price: pack.price,
        units: pack.units + 1,
        imagePath: pack.imagePath,
        items: pack.items,
      );

      await _datasource.updatePack(pack, updatedPack);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡1 unidad montada añadida a "${pack.name}"!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // --- DIÁLOGO DE CREACIÓN / EDICIÓN ---
  void _showPackDialog({Pack? existingPack}) async {
    if (_products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Primero necesitas productos activos en el inventario.',
            ),
          ),
        );
      }
      return;
    }

    String packName = existingPack?.name ?? '';
    double packPrice = existingPack?.price ?? 0.0;
    int packUnits = existingPack?.units ?? 1;
    File? selectedImage =
        (existingPack?.imagePath != null &&
            File(existingPack!.imagePath!).existsSync())
        ? File(existingPack.imagePath!)
        : null;

    final Map<ProductModel, int> selectedItems = {};
    if (existingPack != null) {
      for (var item in existingPack.items) {
        try {
          final prod = _products.firstWhere((p) => p.id == item.productId);
          selectedItems[prod] = item.quantity;
        } catch (_) {}
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingPack == null
                    ? 'Crear Nuevo Pack / Bundle'
                    : 'Modificar Pack',
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            setDialogState(
                              () => selectedImage = File(picked.path),
                            );
                          }
                        },
                        child: Container(
                          height: 85,
                          width: 85,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
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
                                  color: Colors.grey,
                                  size: 30,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: packName),
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Pack',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) => packName = val,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                text: packPrice > 0 ? packPrice.toString() : '',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Precio (€)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) => packPrice =
                                  double.tryParse(val.replaceAll(',', '.')) ??
                                  0.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                text: packUnits.toString(),
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Stock inicial',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) =>
                                  packUnits = int.tryParse(val) ?? 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Piezas por cada 1 unidad de pack:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            final qtyPerPack = selectedItems[product] ?? 0;

                            int previousDeduction = 0;
                            if (existingPack != null) {
                              final prevItem = existingPack.items.firstWhere(
                                (i) => i.productId == product.id,
                                orElse: () => PackItem(
                                  productId: 0,
                                  productName: '',
                                  quantity: 0,
                                ),
                              );
                              previousDeduction =
                                  prevItem.quantity * existingPack.units;
                            }
                            final effectiveAvailable =
                                product.units + previousDeduction;
                            final neededTotal = qtyPerPack * packUnits;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Almacén: $effectiveAvailable uds (Total requerido: $neededTotal)',
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
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      onPressed: qtyPerPack > 0
                                          ? () => setDialogState(
                                              () => selectedItems[product] =
                                                  qtyPerPack - 1,
                                            )
                                          : null,
                                    ),
                                    Text(
                                      '$qtyPerPack',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      onPressed:
                                          ((qtyPerPack + 1) * packUnits) <=
                                              effectiveAvailable
                                          ? () => setDialogState(
                                              () => selectedItems[product] =
                                                  qtyPerPack + 1,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
                    if (packName.isEmpty || packPrice <= 0 || packUnits <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Rellena nombre, precio y unidades válidas.',
                          ),
                        ),
                      );
                      return;
                    }

                    for (var entry in selectedItems.entries) {
                      if (entry.value > 0) {
                        int previousDeduction = 0;
                        if (existingPack != null) {
                          final prevItem = existingPack.items.firstWhere(
                            (i) => i.productId == entry.key.id,
                            orElse: () => PackItem(
                              productId: 0,
                              productName: '',
                              quantity: 0,
                            ),
                          );
                          previousDeduction =
                              prevItem.quantity * existingPack.units;
                        }
                        final effectiveAvailable =
                            entry.key.units + previousDeduction;
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

                    String? imagePath = selectedImage?.path;
                    if (selectedImage != null &&
                        !selectedImage!.path.contains('app_flutter')) {
                      final dir = await getApplicationDocumentsDirectory();
                      final fileName = path_utils.basename(selectedImage!.path);
                      final saved = await selectedImage!.copy(
                        '${dir.path}/$fileName',
                      );
                      imagePath = saved.path;
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

                    if (packItemsList.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Añade al menos 1 producto por pack.'),
                        ),
                      );
                      return;
                    }

                    final newPack = Pack(
                      id: existingPack?.id,
                      name: packName,
                      price: packPrice,
                      units: packUnits,
                      imagePath: imagePath,
                      items: packItemsList,
                    );

                    if (existingPack == null) {
                      await _datasource.createPack(newPack);
                    } else {
                      await _datasource.updatePack(existingPack, newPack);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            existingPack == null
                                ? '¡Pack creado con éxito!'
                                : '¡Pack modificado con éxito!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text(existingPack == null ? 'Crear Pack' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Pack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pack'),
        content: Text(
          '¿Seguro que deseas eliminar "${pack.name}"? Los componentes de los ${pack.units} packs montados volverán al almacén.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _datasource.deletePack(pack);
              if (context.mounted) {
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Pack eliminado y componentes devueltos al almacén.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
        if (dx > 50 && dy.abs() < 30) {
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
        appBar: AppBar(title: const Text('Gestión de Packs y Bundles')),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _packs.isEmpty
            ? const Center(
                child: Text(
                  'No hay packs creados todavía.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _packs.length,
                itemBuilder: (context, index) {
                  final pack = _packs[index];
                  final bool hasValidImage =
                      pack.imagePath != null &&
                      File(pack.imagePath!).existsSync();

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      leading: hasValidImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(pack.imagePath!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Colors.teal,
                                size: 26,
                              ),
                            ),
                      title: Text(
                        pack.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              '${pack.price.toStringAsFixed(2)} €',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // CONTROL RÁPIDO DE UNIDADES MONTADAS (+ / -)
                            Container(
                              decoration: BoxDecoration(
                                color: pack.units > 0
                                    ? Colors.teal.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: pack.units > 0
                                      ? Colors.teal.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: pack.units > 0
                                        ? () => _quickAdjustStock(pack, -1)
                                        : null,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${pack.units} uds',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: pack.units > 0
                                          ? Colors.teal.shade900
                                          : Colors.red.shade900,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _quickAdjustStock(pack, 1),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showPackDialog(existingPack: pack),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(pack),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const Text(
                                'Componentes de 1 unidad de este pack:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...pack.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '• ${item.productName}',
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.quantity} uds/pack',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPackDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
