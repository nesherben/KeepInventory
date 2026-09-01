import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_drawer.dart';

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
  double? _startX;
  double? _startY;

  bool _isLoading = true;
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
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

  // --- MATEMÁTICAS DE LA PROMOCIÓN PARA REEMBOLSOS (Usa el Snapshot del Ticket) ---
  double _calculateItemTotal(SaleItem item, int qtyToKeep) {
    if (item.promoType == null ||
        item.promoThreshold == null ||
        item.promoDiscount == null) {
      return item.originalPrice * qtyToKeep;
    }

    if (item.promoType == 'bundle_fixed_price') {
      final int bundles = qtyToKeep ~/ item.promoThreshold!;
      final int remainder = qtyToKeep % item.promoThreshold!;
      return (bundles * item.promoDiscount!) + (remainder * item.originalPrice);
    } else if (item.promoType == 'percentage') {
      if (qtyToKeep >= item.promoThreshold!) {
        final discountedPrice =
            item.originalPrice * (1 - (item.promoDiscount! / 100));
        return qtyToKeep * discountedPrice;
      }
    }
    return item.originalPrice * qtyToKeep;
  }

  // --- DIÁLOGO DE DEVOLUCIÓN PARCIAL / SELECTIVA ---
  void _showPartialRefundDialog(Sale sale) {
    final Map<SaleItem, int> refundItemQuantities = {
      for (var item in sale.items) item: 0,
    };
    final Map<SalePackItem, int> refundPackQuantities = {
      for (var pack in sale.packItems) pack: 0,
    };

    bool restockPacks = false;
    final TextEditingController refundAmountController = TextEditingController(
      text: '0.00',
    );

    // Aquí se recalcula el ticket si se rompe el bundle
    void recalculateDefaultRefund() {
      double totalRefund = 0.0;

      refundItemQuantities.forEach((item, refundQty) {
        if (refundQty > 0) {
          int keptQty = item.quantity - refundQty;

          // Lo que pagó inicialmente por esta línea de producto
          double originalTotal = item.historicalPrice * item.quantity;

          // Lo que costaría la nueva cantidad (rompiendo o no la promo)
          double newTotal = 0.0;
          if (keptQty > 0) {
            newTotal = _calculateItemTotal(item, keptQty);
          }

          totalRefund += (originalTotal - newTotal);
        }
      });

      // Los packs no tienen promo 3x2, su devolución es proporcional directa
      refundPackQuantities.forEach((pack, refundQty) {
        if (refundQty > 0) {
          totalRefund += pack.historicalPrice * refundQty;
        }
      });

      // Si rompes la oferta y el "newTotal" de lo que te quedas es más caro de lo que pagaste por todo, se devuelve 0.
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
              title: Text('Devolución Ticket #${sale.id}'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Indica cuántas unidades devuelves de cada artículo:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      // 1. LISTA DE PRODUCTOS
                      if (sale.items.isNotEmpty) ...[
                        const Text(
                          'Productos Sueltos:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...sale.items.map((item) {
                          final currentRefundQty =
                              refundItemQuantities[item] ?? 0;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
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
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Pagado: ${(item.quantity * item.historicalPrice).toStringAsFixed(2)} € (Compradas: ${item.quantity})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        onPressed: currentRefundQty > 0
                                            ? () {
                                                setDialogState(
                                                  () =>
                                                      refundItemQuantities[item] =
                                                          currentRefundQty - 1,
                                                );
                                                recalculateDefaultRefund();
                                              }
                                            : null,
                                      ),
                                      Text(
                                        '$currentRefundQty',
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
                                            currentRefundQty < item.quantity
                                            ? () {
                                                setDialogState(
                                                  () =>
                                                      refundItemQuantities[item] =
                                                          currentRefundQty + 1,
                                                );
                                                recalculateDefaultRefund();
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],

                      // 2. LISTA DE PACKS
                      if (sale.packItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Packs / Bundles:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...sale.packItems.map((pack) {
                          final currentRefundQty =
                              refundPackQuantities[pack] ?? 0;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.amber.shade50,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
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
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${pack.historicalPrice.toStringAsFixed(2)} €/pack (Comprados: ${pack.quantity})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        onPressed: currentRefundQty > 0
                                            ? () {
                                                setDialogState(
                                                  () =>
                                                      refundPackQuantities[pack] =
                                                          currentRefundQty - 1,
                                                );
                                                recalculateDefaultRefund();
                                              }
                                            : null,
                                      ),
                                      Text(
                                        '$currentRefundQty',
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
                                            currentRefundQty < pack.quantity
                                            ? () {
                                                setDialogState(
                                                  () =>
                                                      refundPackQuantities[pack] =
                                                          currentRefundQty + 1,
                                                );
                                                recalculateDefaultRefund();
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (hasPacksSelected) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '¿Reincorporar Pack al stock?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Desactívalo si era un pack sorpresa abierto.',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: restockPacks,
                            onChanged: (val) =>
                                setDialogState(() => restockPacks = val),
                          ),
                        ],
                      ],

                      const Divider(height: 20),

                      // TOTAL A REEMBOLSAR (EDITABLE)
                      const Text(
                        'Total a Reembolsar al cliente (€):',
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          isDense: true,
                          helperText: 'Cálculo automático de ruptura de promoción. Puedes editarlo manualmente.',
                          helperStyle: TextStyle(color: Colors.grey.shade600),
                          helperMaxLines: 2,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No puedes devolver más de lo que cobró el ticket.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          await _saleRepository.processPartialRefund(
                            originalSale: sale,
                            itemsToRefund: refundItemQuantities,
                            packsToRefund: refundPackQuantities,
                            restockPacks: restockPacks,
                            customRefundAmount: customRefund,
                          );
                          await _loadSales();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Devolución procesada y contabilidad rebalanceada.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: const Text('Confirmar Devolución'),
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
          title: const Text('Agrupar en Feria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona una feria guardada o escribe el nombre de una nueva:',
              ),
              const SizedBox(height: 16),
              if (existingFairs.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedExisting,
                  decoration: const InputDecoration(
                    labelText: 'Ferias disponibles',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('-- Escribir nueva / Ninguna --'),
                    ),
                    ...existingFairs.map(
                      (fair) =>
                          DropdownMenuItem(value: fair, child: Text(fair)),
                    ),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      selectedExisting = val;
                      if (val != null) {
                        controller.text = val;
                      } else {
                        controller.clear(); // <-- ¡AQUÍ ESTÁ EL TRUCO!
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Feria',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                Navigator.pop(context);
                await _saleRepository.updateFairNameForDate(
                  datePrefix,
                  newName.isEmpty ? null : newName,
                );
                await _loadSales();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month a las $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Sale>> groupedSales = {};
    final Map<String, String> groupDatePrefix = {};

    for (var sale in _sales) {
      final day = sale.date.day.toString().padLeft(2, '0');
      final month = sale.date.month.toString().padLeft(2, '0');
      final year = sale.date.year.toString();
      final dateKey = '$day/$month/$year';
      final datePrefix = '$year-$month-$day';

      final groupKey = (sale.fairName != null && sale.fairName!.isNotEmpty)
          ? '🎪 Feria: ${sale.fairName}'
          : dateKey;

      groupedSales.putIfAbsent(groupKey, () => []).add(sale);
      groupDatePrefix[groupKey] = datePrefix;
    }

    final groupKeys = groupedSales.keys.toList();

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
          title: const Text('Historial y Ferias'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
          ],
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sales.isEmpty
            ? const Center(child: Text('No hay ventas registradas aún.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: groupKeys.length,
                itemBuilder: (context, index) {
                  final groupKey = groupKeys[index];
                  final groupSales = groupedSales[groupKey]!;
                  final datePrefix = groupDatePrefix[groupKey]!;

                  final groupTotal = groupSales.fold(
                    0.0,
                    (sum, sale) => sum + sale.totalAmount,
                  );
                  final isFair = groupKey.startsWith('🎪 Feria:');
                  final currentFairName = isFair
                      ? groupKey.replaceFirst('🎪 Feria: ', '')
                      : '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      collapsedBackgroundColor: isFair
                          ? Colors.amber.shade50
                          : Colors.teal.shade50,
                      backgroundColor:
                          (isFair ? Colors.amber.shade50 : Colors.teal.shade50)
                              .withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              groupKey,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isFair
                                    ? Colors.amber.shade900
                                    : Colors.teal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${groupTotal.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isFair
                                  ? Colors.amber.shade900
                                  : Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text('${groupSales.length} tickets'),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _showAssignFairDialog(
                              datePrefix,
                              currentFairName,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Text(
                                isFair
                                    ? '[Cambiar Feria]'
                                    : '[+ Agrupar en Feria]',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: groupSales.map((sale) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isFair
                                        ? Colors.amber.shade100
                                        : Colors.teal.shade100,
                                    child: Icon(
                                      Icons.receipt_long,
                                      color: isFair
                                          ? Colors.amber.shade900
                                          : Colors.teal.shade800,
                                    ),
                                  ),
                                  title: Text(
                                    'Ticket #${sale.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(_formatDateTime(sale.date)),
                                  trailing: Text(
                                    '${sale.totalAmount.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  children: [
                                    const Divider(height: 1),
                                    Container(
                                      color: Colors.grey[50],
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          // PRODUCTOS SUELTOS
                                          ...sale.items.map((item) {
                                            return ListTile(
                                              dense: true,
                                              leading: const Icon(
                                                Icons.inventory_2_outlined,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              title: Text(
                                                '${item.quantity}x ${item.productName}',
                                              ),
                                              trailing: Text(
                                                '${(item.quantity * item.historicalPrice).toStringAsFixed(2)} €',
                                              ),
                                            );
                                          }),

                                          // PACKS Y BUNDLES
                                          ...sale.packItems.map((packItem) {
                                            return ListTile(
                                              dense: true,
                                              leading: const Icon(
                                                Icons.card_giftcard,
                                                size: 18,
                                                color: Colors.amber,
                                              ),
                                              title: Text(
                                                '${packItem.quantity}x ${packItem.packName} (Pack)',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              trailing: Text(
                                                '${(packItem.quantity * packItem.historicalPrice).toStringAsFixed(2)} €',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.amber.shade900,
                                                ),
                                              ),
                                            );
                                          }),

                                          const Divider(height: 16),

                                          // BOTÓN GESTIÓN DE DEVOLUCIONES
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 8.0,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.undo,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'Gestionar Devolución',
                                                ),
                                                onPressed: () =>
                                                    _showPartialRefundDialog(
                                                      sale,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
    );
  }
}
