import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos las nuevas Alertas

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
  double? _startX;
  double? _startY;

  List<Pack> _packs = [];
  List<Product> _availableProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Llamadas a cada repositorio
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
        // 💡 Reemplazado por AppAlerts
        AppAlerts.showInfo(
          context,
          '1 unidad de "${pack.name}" desmontada. Componentes devueltos al almacén.',
        );
      }
    } else if (delta > 0) {
      // 1. Validar que hay stock de todos los componentes en el almacén
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
            // 💡 Reemplazado por AppAlerts de Error
            AppAlerts.showError(
              context,
              'Falta stock de "${item.productName}" (necesitas $missingQty uds más en almacén).',
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
        imageBytes: pack.imageBytes,
        items: pack.items,
      );

      await _packRepository.updatePack(pack, updatedPack);
      await _loadData();

      if (mounted) {
        // 💡 Reemplazado por AppAlerts de Éxito
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
        // 💡 Reemplazado por AppAlerts
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
            // 💡 Reemplazado por AppAlerts
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
            // 💡 Adaptado al theme (modo claro y oscuro)
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await _packRepository.deletePack(pack);
              if (context.mounted) {
                Navigator.pop(context);
                _loadData();
                // 💡 Usamos showWarning ya que antes el color era naranja
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
            ? Center(
                child: Text(
                  'No hay packs creados todavía.',
                  style: TextStyle(
                    // 💡 Color dinámico para el texto
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _packs.length,
                itemBuilder: (context, index) {
                  final pack = _packs[index];

                  return PackListItem(
                    pack: pack,
                    onEdit: (pack) => _showPackDialog(existingPack: pack),
                    onDelete: (pack) => _confirmDelete(pack),
                    onQuickAdjust: _quickAdjustStock,
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
