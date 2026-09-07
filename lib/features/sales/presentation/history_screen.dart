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
  String _searchQuery =
      ''; // 💡 Variable para el buscador de tickets/ferias/productos

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

  // --- MATEMÁTICAS DE LA PROMOCIÓN PARA REEMBOLSOS ---
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

    void recalculateDefaultRefund() {
      double totalRefund = 0.0;

      refundItemQuantities.forEach((item, refundQty) {
        if (refundQty > 0) {
          int keptQty = item.quantity - refundQty;
          double originalTotal = item.historicalPrice * item.quantity;
          double newTotal = 0.0;
          if (keptQty > 0) {
            newTotal = _calculateItemTotal(item, keptQty);
          }
          totalRefund += (originalTotal - newTotal);
        }
      });

      refundPackQuantities.forEach((pack, refundQty) {
        if (refundQty > 0) {
          totalRefund += pack.historicalPrice * refundQty;
        }
      });

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
                      Text(
                        'Indica cuántas unidades devuelves de cada artículo:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1. PRODUCTOS SUELTOS
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
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
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
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

                      // 2. PACKS
                      if (sale.packItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Packs / Bundles:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...sale.packItems.map((pack) {
                          final currentRefundQty =
                              refundPackQuantities[pack] ?? 0;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
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
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
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
                            subtitle: Text(
                              'Desactívalo si era un pack sorpresa abierto.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            value: restockPacks,
                            onChanged: (val) =>
                                setDialogState(() => restockPacks = val),
                          ),
                        ],
                      ],

                      const Divider(height: 20),

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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          isDense: true,
                          helperText: 'Cálculo automático de ruptura de promoción. Puedes editarlo manualmente.',
                          helperStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
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
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
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
                            restockPacks: restockPacks,
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
                        controller.clear();
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
                if (mounted) {
                  AppAlerts.showSuccess(
                    context,
                    newName.isEmpty
                        ? 'Feria desasignada correctamente.'
                        : 'Ventas agrupadas en "$newName" con éxito.',
                  );
                }
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
    // 💡 Lógica de filtrado inteligente: busca en nombre de feria, ID de ticket y nombres de artículos o packs
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
          ? '🎪 Feria: ${sale.fairName}'
          : dateKey;

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
          title: const Text('Historial y Ferias'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
          ],
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // --- 💡 BARRA DE BÚSQUEDA DE TICKETS Y FERIAS ---
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
                            'Buscar por feria, ID de ticket o artículo...',
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

                  // --- LISTADO DE HISTORIAL Y FERIAS ---
                  Expanded(
                    child: groupKeys.isEmpty
                        ? Center(
                            child: Text(
                              _sales.isEmpty
                                  ? 'No hay ventas registradas aún.'
                                  : 'No se encontraron tickets con esa búsqueda.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          )
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

                              final baseThemeColor = isFair
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary;

                              final groupHeaderColor = baseThemeColor
                                  .withValues(alpha: 0.12);
                              final groupHeaderTextColor = baseThemeColor;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  collapsedBackgroundColor: groupHeaderColor,
                                  backgroundColor: groupHeaderColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          groupKey,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: groupHeaderTextColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${groupTotal.toStringAsFixed(2)} €',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: groupHeaderTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        '${groupSales.length} tickets',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      InkWell(
                                        onTap: () => _showAssignFairDialog(
                                          datePrefix,
                                          currentFairName,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                            vertical: 4.0,
                                          ),
                                          child: Text(
                                            isFair
                                                ? '[Cambiar Feria]'
                                                : '[+ Agrupar en Feria]',
                                            style: TextStyle(
                                              color: groupHeaderTextColor,
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
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            elevation: 1,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: ExpansionTile(
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    groupHeaderColor,
                                                child: Icon(
                                                  Icons.receipt_long,
                                                  color: groupHeaderTextColor,
                                                ),
                                              ),
                                              title: Text(
                                                'Ticket #${sale.id}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                _formatDateTime(sale.date),
                                              ),
                                              trailing: Text(
                                                '${sale.totalAmount.toStringAsFixed(2)} €',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              children: [
                                                const Divider(height: 1),
                                                Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.3),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      // PRODUCTOS SUELTOS
                                                      ...sale.items.map((item) {
                                                        return ListTile(
                                                          dense: true,
                                                          leading: Icon(
                                                            Icons
                                                                .inventory_2_outlined,
                                                            size: 18,
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
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
                                                      ...sale.packItems.map((
                                                        packItem,
                                                      ) {
                                                        return ListTile(
                                                          dense: true,
                                                          leading: Icon(
                                                            Icons.card_giftcard,
                                                            size: 18,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .secondary,
                                                          ),
                                                          title: Text(
                                                            '${packItem.quantity}x ${packItem.packName} (Pack)',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          trailing: Text(
                                                            '${(packItem.quantity * packItem.historicalPrice).toStringAsFixed(2)} €',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .secondary,
                                                            ),
                                                          ),
                                                        );
                                                      }),

                                                      const Divider(height: 16),

                                                      // BOTÓN GESTIÓN DE DEVOLUCIONES
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16.0,
                                                              vertical: 8.0,
                                                            ),
                                                        child: SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: OutlinedButton.icon(
                                                            style: OutlinedButton.styleFrom(
                                                              foregroundColor:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .error,
                                                              side: BorderSide(
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.error,
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
                ],
              ),
      ),
    );
  }
}
