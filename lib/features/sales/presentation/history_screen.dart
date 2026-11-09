import 'package:flutter/material.dart';

import '../../../core/shared_widgets/app_ui.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart';

// Imports de la feature SALES
import '../data/repositories/sale_repository_imp.dart';
import '../domain/sale.dart';
import '../data/datasources/sale_local_datasource.dart';
import 'sale_history_group.dart';
import 'widgets/partial_refund_dialog.dart';
import 'widgets/sale_history_group_card.dart';

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
    // Sin indicador de carga al recargar: se conserva la posición del scroll
    final sales = await _saleRepository.getSales();
    sales.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }

  void _showPartialRefundDialog(Sale sale) {
    showDialog<void>(
      context: context,
      builder: (_) => PartialRefundDialog(
        sale: sale,
        onConfirm:
            ({
              required itemsToRefund,
              required packsToRefund,
              required restockAsComponents,
              required customRefundAmount,
            }) async {
              await _saleRepository.processPartialRefund(
                originalSale: sale,
                itemsToRefund: itemsToRefund,
                packsToRefund: packsToRefund,
                restockAsComponents: restockAsComponents,
                customRefundAmount: customRefundAmount,
              );
              await _loadSales();

              if (!mounted) return;
              AppAlerts.showSuccess(context, context.l10n.refundSuccess);
            },
      ),
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
          title: Text(
            context.l10n.assignFairTitle,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.selectFairPrompt),
              const SizedBox(height: 16),
              if (existingFairs.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedExisting,
                  decoration: InputDecoration(
                    labelText: context.l10n.availableFairs,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.event_seat),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        context.l10n.enterNewFairOrNone,
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
                  labelText: context.l10n.fairName,
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
              child: Text(
                context.l10n.cancel,
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
                final l10n = context.l10n;
                final newName = controller.text.trim();
                Navigator.pop(context);
                await _saleRepository.updateFairNameForDate(
                  datePrefix,
                  newName.isEmpty ? null : newName,
                );
                await _loadSales();
                if (!context.mounted) return;
                AppAlerts.showSuccess(
                  context,
                  newName.isEmpty
                      ? l10n.fairUnassigned
                      : l10n.salesGroupedFair(newName),
                );
              },
              icon: const Icon(Icons.save, size: 18),
              label: Text(
                context.l10n.save,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = filterAndGroupSales(_sales, _searchQuery);

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
          title: Text(context.l10n.refundTitleHistory),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchHistory,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),
                  ),

                  // --- LISTADO DE HISTORIAL ---
                  Expanded(
                    child: groups.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: _sales.isEmpty
                                ? context.l10n.salesHistoryEmpty
                                : context.l10n.historyNoResults,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: groups.length,
                            itemBuilder: (context, index) =>
                                SaleHistoryGroupCard(
                                  group: groups[index],
                                  onAssignFair: _showAssignFairDialog,
                                  onRefund: _showPartialRefundDialog,
                                ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
