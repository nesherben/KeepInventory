import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';

// Imports de la feature PACKS
import '../../inventory/data/repositories/product_repository_impl.dart';

import '../data/repositories/pack_repository_impl.dart';
import '../domain/pack.dart';
import '../data/datasources/pack_local_datasource.dart';

// Imports de la feature INVENTORY
import '../../inventory/domain/product.dart';
import '../../inventory/data/datasources/product_local_datasource.dart';

// Widget Composition
import 'widgets/pack_form_dialog.dart';
import 'widgets/pack_list_item.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  // Instanciamos los repositorios necesarios
  final _packRepository = PackRepositoryImpl(PackLocalDatasource());
  final _productRepository = ProductRepositoryImpl(ProductLocalDatasource());

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  double? _startX;
  double? _startY;

  List<Pack> _packs = [];
  List<Product> _availableProducts = [];
  bool _isLoading = true;

  // 💡 Variable para el texto de búsqueda
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final packs = await _packRepository.getPacks();
    final products = await _productRepository.getProducts();

    if (!mounted) return;
    setState(() {
      _packs = packs;
      _availableProducts = products;
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
        imageBytes: pack.imageBytes,
        items: pack.items,
      );

      await _packRepository.updatePack(pack, updatedPack);
      await _loadData();

      if (mounted) {
        AppAlerts.showInfo(
          context,
          '1 unidad de "${pack.name}" desmontada. Componentes devueltos al almacén.',
        );
      }
    } else if (delta > 0) {
      for (var item in pack.items) {
        Product? productInStock;
        try {
          productInStock = _availableProducts.firstWhere(
            (p) => p.id == item.productId,
          );
        } catch (_) {}

        if (productInStock == null || productInStock.units < item.quantity) {
          final missingQty = item.quantity - (productInStock?.units ?? 0);
          if (mounted) {
            AppAlerts.showError(
              context,
              'Falta stock de "${item.productName}" (necesitas $missingQty uds más en almacén).',
            );
          }
          return;
        }
      }

      final updatedPack = Pack(
        id: pack.id,
        name: pack.name,
        price: pack.price,
        units: pack.units + 1,
        imagePath: pack.imagePath,
        imageBytes: pack.imageBytes,
        items: pack.items,
      );

      await _packRepository.updatePack(pack, updatedPack);
      await _loadData();

      if (mounted) {
        AppAlerts.showSuccess(
          context,
          '¡1 unidad montada añadida a "${pack.name}"!',
        );
      }
    }
  }

  // --- DIÁLOGO DE CREACIÓN / EDICIÓN ---
  void _showPackDialog({Pack? existingPack}) async {
    if (_availableProducts.isEmpty) {
      if (mounted) {
        AppAlerts.showWarning(
          context,
          'Primero necesitas productos activos en el inventario.',
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => PackFormDialog(
        existingPack: existingPack,
        availableProducts: _availableProducts,
        onSave: (newPack) async {
          if (existingPack == null) {
            await _packRepository.createPack(newPack);
          } else {
            await _packRepository.updatePack(existingPack, newPack);
          }

          if (context.mounted) {
            Navigator.pop(context);
            _loadData();
            AppAlerts.showSuccess(
              context,
              existingPack == null
                  ? '¡Pack creado con éxito!'
                  : '¡Pack modificado con éxito!',
            );
          }
        },
      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await _packRepository.deletePack(pack);
              if (context.mounted) {
                Navigator.pop(context);
                _loadData();
                AppAlerts.showWarning(
                  context,
                  'Pack eliminado y componentes devueltos al almacén.',
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Lógica de filtrado inteligente: Busca por nombre del pack O por nombre de sus componentes internos
    final filteredPacks = _packs.where((pack) {
      final query = _searchQuery.toLowerCase();

      // 1. ¿El pack coincide por su propio nombre?
      final matchesPackName = pack.name.toLowerCase().contains(query);

      // 2. ¿Algún producto dentro del pack coincide con la búsqueda?
      final matchesItemName = pack.items.any(
        (item) => item.productName.toLowerCase().contains(query),
      );

      return matchesPackName || matchesItemName;
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
            : Column(
                children: [
                  // --- 💡 BARRA DE BÚSQUEDA ---
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText:
                            'Buscar pack o producto dentro de los packs...',
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

                  // --- LISTADO DE PACKS ---
                  Expanded(
                    child: filteredPacks.isEmpty
                        ? Center(
                            child: Text(
                              _packs.isEmpty ? 'No hay packs creados todavía.' : 'No se encontraron packs o componentes con ese nombre.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredPacks.length,
                            itemBuilder: (context, index) {
                              final pack = filteredPacks[index];

                              return PackListItem(
                                pack: pack,
                                onEdit: (pack) =>
                                    _showPackDialog(existingPack: pack),
                                onDelete: (pack) => _confirmDelete(pack),
                                onQuickAdjust: _quickAdjustStock,
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPackDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
