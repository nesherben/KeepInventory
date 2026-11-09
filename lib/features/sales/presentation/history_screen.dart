import '../../../core/shared_widgets/name_picker_sheet.dart';

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

  /// Panel de ferias: buscador arriba, tocar una feria la asigna al momento;
  /// si lo escrito no existe, "Crear «X»". Cada feria se puede borrar de la
  /// lista con su papelera.
  ///
  /// Grupo de un día ([currentFairName] vacío): se asigna a ese día.
  /// Grupo de feria: el cambio afecta a TODOS sus tickets, de cualquier día.
  void _showAssignFairDialog(String datePrefix, String currentFairName) async {
    final existingFairs = await _saleRepository.getAvailableFairs();
    if (!mounted) return;
    var deletedAny = false;
    final l10n = context.l10n;

    final chosen = await showNamePickerSheet(
      context,
      title: l10n.assignFairTitle,
      searchHint: l10n.fairSearchOrCreate,
      names: existingFairs,
      createLabel: l10n.fairCreate,
      current: currentFairName,
      currentLabel: l10n.fairCurrent,
      removeLabel: l10n.fairRemove,
      deleteTooltip: l10n.fairDeleteTitle,
      icon: Icons.event_outlined,
      onDelete: (sheetContext, fair) async {
        final deleted = await _deleteFair(sheetContext, fair);
        deletedAny |= deleted;
        return deleted;
      },
    );

    if (chosen == null || chosen == currentFairName) {
      if (deletedAny) await _loadSales();
      return;
    }
    final newFair = chosen.isEmpty ? null : chosen;
    if (currentFairName.isNotEmpty) {
      // Grupo de feria: todos sus tickets, sean del día que sean
      await _saleRepository.reassignFair(currentFairName, newFair);
    } else {
      await _saleRepository.updateFairNameForDate(datePrefix, newFair);
    }
    await _loadSales();
    if (!mounted) return;
    AppAlerts.showSuccess(
      context,
      chosen.isEmpty
          ? context.l10n.fairUnassigned
          : context.l10n.salesGroupedFair(chosen),
    );
  }

  /// Pregunta y borra una feria del catálogo (sus tickets quedan sin feria).
  Future<bool> _deleteFair(BuildContext sheetContext, String fair) async {
    final count = await _saleRepository.countSalesForFair(fair);
    if (!sheetContext.mounted) return false;
    final l10n = sheetContext.l10n;
    final ok = await confirmDeleteDialog(
      sheetContext,
      title: l10n.fairDeleteTitle,
      message: count > 0
          ? l10n.fairDeleteConfirmUsed(count, fair)
          : l10n.fairDeleteConfirmEmpty(fair),
      cancelLabel: l10n.cancel,
      deleteLabel: l10n.delete,
    );
    if (!ok) return false;
    await _saleRepository.deleteFair(fair);
    if (mounted) AppAlerts.showWarning(context, l10n.fairDeleted);
    return true;
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
