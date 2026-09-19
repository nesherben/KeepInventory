import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';

// Imports de la feature SALES
import '../data/repositories/sale_repository_imp.dart';
import '../domain/sale.dart';
import '../data/datasources/sale_local_datasource.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Instanciamos SOLO el repositorio de ventas
  final _saleRepository = SaleRepositoryImpl(SaleLocalDatasource());

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  double? _startX;
  double? _startY;

  bool _isLoading = true;
  List<Sale> _sales = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final sales = await _saleRepository.getSales();
    sales.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }

  // 💡 NUEVO ALGORITMO: Simula el carrito resultante tras la devolución para recalcular promociones combinadas
  double _calculateRemainingCartValue(
    Map<SaleItem, int> keptItemQuantities,
    Map<SalePackItem, int> keptPackQuantities,
  ) {
    double totalValue = 0.0;

    // 1. Añadimos el valor de los Packs (No tienen ofertas combinadas, usan precio histórico)
    keptPackQuantities.forEach((pack, keptQty) {
      totalValue += pack.historicalPrice * keptQty;
    });

    // 2. Evaluamos los Productos Sueltos
    // Agrupamos por ID de promoción para aplicar Mix & Match
    Map<int?, List<SaleItem>> itemsByPromo = {};
    for (var entry in keptItemQuantities.entries) {
      final item = entry.key;
      if (entry.value > 0) {
        itemsByPromo.putIfAbsent(item.promotionId, () => []).add(item);
      }
    }

    for (var entry in itemsByPromo.entries) {
      final promoId = entry.key;
      final groupItems = entry.value;

      if (promoId == null) {
        // Sin promoción: se cobra al precio original
        for (var item in groupItems) {
          totalValue += item.originalPrice * keptItemQuantities[item]!;
        }
      } else {
        // Con promoción: evaluamos si entre todos llegan al mínimo
        final firstItem = groupItems.first;
        final promoType = firstItem.promoType;
        final promoThreshold = firstItem.promoThreshold;
        final promoDiscount = firstItem.promoDiscount;

        if (promoType == null ||
            promoThreshold == null ||
            promoDiscount == null) {
          for (var item in groupItems) {
            totalValue += item.originalPrice * keptItemQuantities[item]!;
          }
          continue;
        }

        int combinedQty = groupItems.fold(
          0,
          (sum, item) => sum + keptItemQuantities[item]!,
        );

        if (combinedQty < promoThreshold) {
          // ⚠️ LA OFERTA SE HA ROTO: Cobramos todo a precio original
          for (var item in groupItems) {
            totalValue += item.originalPrice * keptItemQuantities[item]!;
          }
        } else {
          // LA OFERTA SE MANTIENE
          if (promoType == 'percentage') {
            for (var item in groupItems) {
              double discountedUnit =
                  item.originalPrice * (1 - (promoDiscount / 100));
              totalValue += keptItemQuantities[item]! * discountedUnit;
            }
          } else if (promoType == 'bundle_fixed_price') {
            // Mix & Match (Desplegamos unidades y ordenamos por precio original)
            List<SaleItem> flatList = [];
            for (var item in groupItems) {
              for (int i = 0; i < keptItemQuantities[item]!; i++) {
                flatList.add(item);
              }
            }
            flatList.sort((a, b) => b.originalPrice.compareTo(a.originalPrice));

            double pricePerBundleItem = promoDiscount / promoThreshold;

            for (int i = 0; i < flatList.length; i++) {
              bool isInsideBundle =
                  i < (flatList.length ~/ promoThreshold) * promoThreshold;
              if (isInsideBundle) {
                totalValue += pricePerBundleItem;
              } else {
                totalValue += flatList[i].originalPrice;
              }
            }
          }
        }
      }
    }
    return totalValue;
  }

  // --- DIÁLOGO DE DEVOLUCIÓN PARCIAL / SELECTIVA ---
  void _showPartialRefundDialog(Sale sale) {
    final Map<SaleItem, int> refundItemQuantities = {
      for (var item in sale.items) item: 0,
    };
    final Map<SalePackItem, int> refundPackQuantities = {
      for (var pack in sale.packItems) pack: 0,
    };

    bool restockAsComponents = false;
    final TextEditingController refundAmountController = TextEditingController(
      text: '0.00',
    );

    void recalculateDefaultRefund() {
      // Calculamos qué cantidades SE QUEDA el cliente
      final Map<SaleItem, int> keptItemQuantities = {};
      final Map<SalePackItem, int> keptPackQuantities = {};

      for (var item in sale.items) {
        keptItemQuantities[item] =
            item.quantity - (refundItemQuantities[item] ?? 0);
      }
      for (var pack in sale.packItems) {
        keptPackQuantities[pack] =
            pack.quantity - (refundPackQuantities[pack] ?? 0);
      }

      // Calculamos cuánto vale la compra que le queda en las manos
      final double newTotalValue = _calculateRemainingCartValue(
        keptItemQuantities,
        keptPackQuantities,
      );

      // El reembolso justo es la diferencia entre lo que pagó y lo que vale lo que se queda
      double totalRefund = sale.totalAmount - newTotalValue;
      if (totalRefund < 0) totalRefund = 0.0;

      refundAmountController.text = totalRefund.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int totalItemsToRefund = 0;
            refundItemQuantities.forEach((_, qty) => totalItemsToRefund += qty);
            refundPackQuantities.forEach((_, qty) => totalItemsToRefund += qty);

            final bool hasPacksSelected = refundPackQuantities.values.any(
              (qty) => qty > 0,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Devolución Ticket #${sale.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indica cuántas unidades devuelves de cada artículo:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. PRODUCTOS SUELTOS
                      if (sale.items.isNotEmpty) ...[
                        Text(
                          'Productos Sueltos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sale.items.map((item) {
                          final currentRefundQty =
                              refundItemQuantities[item] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName ?? 'Desconocido',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Compradas: ${item.quantity}  •  Abonado: ${(item.quantity * item.historicalPrice).toStringAsFixed(2)} €',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            size: 18,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: currentRefundQty > 0
                                              ? () {
                                                  setDialogState(
                                                    () =>
                                                        refundItemQuantities[item] =
                                                            currentRefundQty -
                                                            1,
                                                  );
                                                  recalculateDefaultRefund();
                                                }
                                              : null,
                                        ),
                                        Text(
                                          '$currentRefundQty',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 18,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed:
                                              currentRefundQty < item.quantity
                                              ? () {
                                                  setDialogState(
                                                    () =>
                                                        refundItemQuantities[item] =
                                                            currentRefundQty +
                                                            1,
                                                  );
                                                  recalculateDefaultRefund();
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],

                      // 2. PACKS
                      if (sale.packItems.isNotEmpty) ...[
                        Text(
                          'Packs / Bundles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sale.packItems.map((pack) {
                          final currentRefundQty =
                              refundPackQuantities[pack] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${pack.packName} (Pack)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Comprados: ${pack.quantity}  •  Abonado: ${(pack.quantity * pack.historicalPrice).toStringAsFixed(2)} €',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            size: 18,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: currentRefundQty > 0
                                              ? () {
                                                  setDialogState(
                                                    () =>
                                                        refundPackQuantities[pack] =
                                                            currentRefundQty -
                                                            1,
                                                  );
                                                  recalculateDefaultRefund();
                                                }
                                              : null,
                                        ),
                                        Text(
                                          '$currentRefundQty',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 18,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed:
                                              currentRefundQty < pack.quantity
                                              ? () {
                                                  setDialogState(
                                                    () =>
                                                        refundPackQuantities[pack] =
                                                            currentRefundQty +
                                                            1,
                                                  );
                                                  recalculateDefaultRefund();
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (hasPacksSelected) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: SwitchListTile(
                              dense: true,
                              title: const Text(
                                'Pack abierto (Devolver piezas)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Suma stock a los artículos individuales.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              value: restockAsComponents,
                              activeThumbColor: Theme.of(context)
                                  .colorScheme
                                  .error,
                              onChanged: (val) => setDialogState(
                                () => restockAsComponents = val,
                              ),
                            ),
                          ),
                        ],
                      ],

                      const Divider(height: 32),

                      const Text(
                        'Total a Reembolsar al cliente (€)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: refundAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: 0.1),
                          prefixIcon: Icon(
                            Icons.payments,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          isDense: true,
                          helperText: 'Cálculo automático de ruptura de promoción. Editable si es necesario.',
                          helperMaxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: totalItemsToRefund == 0
                      ? null
                      : () async {
                          final double customRefund =
                              double.tryParse(
                                refundAmountController.text.replaceAll(
                                  ',',
                                  '.',
                                ),
                              ) ??
                              0.0;

                          if (customRefund > sale.totalAmount) {
                            AppAlerts.showError(
                              context,
                              'No puedes devolver más de lo que cobró el ticket.',
                            );
                            return;
                          }

                          Navigator.pop(context);
                          await _saleRepository.processPartialRefund(
                            originalSale: sale,
                            itemsToRefund: refundItemQuantities,
                            packsToRefund: refundPackQuantities,
                            restockAsComponents: restockAsComponents,
                            customRefundAmount: customRefund,
                          );
                          await _loadSales();

                          if (mounted) {
                            AppAlerts.showSuccess(
                              context,
                              'Devolución procesada y contabilidad rebalanceada.',
                            );
                          }
                        },
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text(
                    'Confirmar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAssignFairDialog(String datePrefix, String currentFairName) async {
    final List<String> existingFairs = await _saleRepository
        .getAvailableFairs();

    final TextEditingController controller = TextEditingController(
      text: currentFairName,
    );
    String? selectedExisting = existingFairs.contains(currentFairName)
        ? currentFairName
        : null;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Agrupar en Feria',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona una feria guardada o escribe una nueva:'),
              const SizedBox(height: 16),
              if (existingFairs.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedExisting,
                  decoration: InputDecoration(
                    labelText: 'Ferias disponibles',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.event_seat),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        '-- Escribir nueva / Ninguna --',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...existingFairs.map(
                      (fair) => DropdownMenuItem(
                        value: fair,
                        child: Text(fair, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      selectedExisting = val;
                      if (val != null) {
                        controller.text = val;
                      } else {
                        controller.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Feria',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
                autofocus: true,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final newName = controller.text.trim();
                Navigator.pop(context);
                await _saleRepository.updateFairNameForDate(
                  datePrefix,
                  newName.isEmpty ? null : newName,
                );
                await _loadSales();
                if (mounted) {
                  AppAlerts.showSuccess(
                    context,
                    newName.isEmpty
                        ? 'Feria desasignada correctamente.'
                        : 'Ventas agrupadas en "$newName" con éxito.',
                  );
                }
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = _sales.where((sale) {
      final query = _searchQuery.toLowerCase();

      final matchesFair =
          sale.fairName != null && sale.fairName!.toLowerCase().contains(query);
      final matchesTicketId = sale.id.toString().contains(query);

      final matchesItem = sale.items.any(
        (item) => (item.productName ?? '').toLowerCase().contains(query),
      );
      final matchesPack = sale.packItems.any(
        (pack) => pack.packName.toLowerCase().contains(query),
      );

      return matchesFair || matchesTicketId || matchesItem || matchesPack;
    }).toList();

    final Map<String, List<Sale>> groupedSales = {};
    final Map<String, String> groupDatePrefix = {};

    for (var sale in filteredSales) {
      final day = sale.date.day.toString().padLeft(2, '0');
      final month = sale.date.month.toString().padLeft(2, '0');
      final year = sale.date.year.toString();
      final dateKey = '$day/$month/$year';
      final datePrefix = '$year-$month-$day';

      final groupKey = (sale.fairName != null && sale.fairName!.isNotEmpty)
          ? '🎪 ${sale.fairName}'
          : '📅 $dateKey';

      groupedSales.putIfAbsent(groupKey, () => []).add(sale);
      groupDatePrefix[groupKey] = datePrefix;
    }

    final List<String> groupKeys = groupedSales.keys.toList();

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
        appBar: AppBar(
          title: const Text(
            'Historial y Ferias',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
          ],
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // --- BARRA DE BÚSQUEDA ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar ticket, artículo, feria...',
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  // --- LISTADO DE HISTORIAL ---
                  Expanded(
                    child: groupKeys.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _sales.isEmpty
                                      ? 'No hay ventas registradas aún.'
                                      : 'No hay resultados para tu búsqueda.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: groupKeys.length,
                            itemBuilder: (context, index) {
                              final groupKey = groupKeys[index];
                              final groupSales = groupedSales[groupKey]!;
                              final datePrefix = groupDatePrefix[groupKey]!;

                              final groupTotal = groupSales.fold(
                                0.0,
                                (sum, sale) => sum + sale.totalAmount,
                              );

                              final isFair = groupKey.startsWith('🎪');
                              final currentFairName = isFair
                                  ? groupKey.replaceFirst('🎪 ', '')
                                  : '';

                              final theme = Theme.of(context);

                              final baseThemeColor = isFair
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primary;

                              final headerColor = baseThemeColor.withValues(
                                alpha: 0.12,
                              );
                              final headerTextColor = baseThemeColor;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 20),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  backgroundColor: theme.colorScheme.surface,
                                  collapsedBackgroundColor: headerColor,
                                  shape: const Border(),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              groupKey,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                                color: headerTextColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${groupSales.length} tickets registrados',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: headerTextColor
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface
                                              .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${groupTotal.toStringAsFixed(2)} €',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: headerTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: ActionChip(
                                        avatar: Icon(
                                          isFair
                                              ? Icons.edit
                                              : Icons.add_circle,
                                          size: 16,
                                          color: headerTextColor,
                                        ),
                                        label: Text(
                                          isFair
                                              ? 'Cambiar Feria'
                                              : 'Agrupar en Feria',
                                          style: TextStyle(
                                            color: headerTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor:
                                            theme.colorScheme.surface,
                                        side: BorderSide(
                                          color: headerTextColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        onPressed: () => _showAssignFairDialog(
                                          datePrefix,
                                          currentFairName,
                                        ),
                                      ),
                                    ),
                                  ),
                                  children: [
                                    Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.2),
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: groupSales.map((sale) {
                                          return Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            elevation: 2,
                                            shadowColor: Colors.black
                                                .withValues(alpha: 0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Theme(
                                              data: theme.copyWith(
                                                dividerColor:
                                                    Colors.transparent,
                                              ),
                                              child: ExpansionTile(
                                                tilePadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                leading: CircleAvatar(
                                                  backgroundColor: headerColor,
                                                  foregroundColor:
                                                      headerTextColor,
                                                  child: const Icon(
                                                    Icons.receipt_long,
                                                  ),
                                                ),
                                                title: Text(
                                                  'Ticket #${sale.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                subtitle: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 14,
                                                      color: theme
                                                          .colorScheme
                                                          .outline,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatDateTime(
                                                        sale.date,
                                                      ),
                                                      style: TextStyle(
                                                        color: theme
                                                            .colorScheme
                                                            .outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                trailing: Text(
                                                  '${sale.totalAmount.toStringAsFixed(2)} €',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 18,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            bottom:
                                                                Radius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          16,
                                                          0,
                                                          16,
                                                          16,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Divider(
                                                          height: 16,
                                                        ),
                                                        ...sale.items.map((
                                                          item,
                                                        ) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 6.0,
                                                                ),
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  '${item.quantity}x',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        item.productName ?? 'Desconocido',
                                                                        style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                      if (item.historicalPrice <
                                                                          item.originalPrice)
                                                                        Text(
                                                                          'Dto aplicado',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                11,
                                                                            color:
                                                                                theme.colorScheme.tertiary,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '${(item.quantity * item.historicalPrice).toStringAsFixed(2)} €',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }),
                                                        if (sale
                                                                .packItems
                                                                .isNotEmpty &&
                                                            sale
                                                                .items
                                                                .isNotEmpty)
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                        ...sale.packItems.map((
                                                          packItem,
                                                        ) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 6.0,
                                                                ),
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  '${packItem.quantity}x',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                    color: theme
                                                                        .colorScheme
                                                                        .secondary,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        packItem
                                                                            .packName,
                                                                        style: TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color: theme
                                                                              .colorScheme
                                                                              .secondary,
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        margin: const EdgeInsets.only(
                                                                          top:
                                                                              2,
                                                                        ),
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              6,
                                                                          vertical:
                                                                              2,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color: theme
                                                                              .colorScheme
                                                                              .secondaryContainer,
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                        ),
                                                                        child: Text(
                                                                          'PACK',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                9,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                theme.colorScheme.onSecondaryContainer,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '${(packItem.quantity * packItem.historicalPrice).toStringAsFixed(2)} €',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: theme
                                                                        .colorScheme
                                                                        .secondary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: FilledButton.tonalIcon(
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor: theme
                                                                  .colorScheme
                                                                  .errorContainer,
                                                              foregroundColor: theme
                                                                  .colorScheme
                                                                  .onErrorContainer,
                                                            ),
                                                            icon: const Icon(
                                                              Icons.undo,
                                                              size: 18,
                                                            ),
                                                            label: const Text(
                                                              'Devolución',
                                                            ),
                                                            onPressed: () =>
                                                                _showPartialRefundDialog(
                                                                  sale,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
