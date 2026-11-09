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

  /// Panel para asignar feria a un día: buscador arriba, tocar una feria la
  /// asigna al momento; si lo escrito no existe, "Crear «X»".
  void _showAssignFairDialog(String datePrefix, String currentFairName) async {
    final existingFairs = await _saleRepository.getAvailableFairs();
    existingFairs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;

    var query = '';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final colors = Theme.of(sheetContext).colorScheme;
          final typed = query.trim();
          final visible = existingFairs
              .where((f) => f.toLowerCase().contains(typed.toLowerCase()))
              .toList();
          final exactExists = existingFairs.any(
            (f) => f.toLowerCase() == typed.toLowerCase(),
          );
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      sheetContext.l10n.assignFairTitle,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: existingFairs.isEmpty,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => setSheet(() => query = v),
                      // Enter: crea / elige lo escrito
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          Navigator.pop(sheetContext, v.trim());
                        }
                      },
                      decoration: InputDecoration(
                        hintText: sheetContext.l10n.fairSearchOrCreate,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        if (typed.isNotEmpty && !exactExists)
                          ListTile(
                            leading: Icon(Icons.add, color: colors.primary),
                            title: Text(
                              sheetContext.l10n.fairCreate(typed),
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => Navigator.pop(sheetContext, typed),
                          ),
                        for (final fair in visible)
                          ListTile(
                            leading: const Icon(Icons.event_outlined),
                            title: Text(fair),
                            selected: fair == currentFairName,
                            trailing: fair == currentFairName
                                ? Text(sheetContext.l10n.fairCurrent)
                                : null,
                            onTap: () => Navigator.pop(sheetContext, fair),
                          ),
                        if (currentFairName.isNotEmpty)
                          ListTile(
                            leading: Icon(
                              Icons.event_busy_outlined,
                              color: colors.error,
                            ),
                            title: Text(
                              sheetContext.l10n.fairRemove,
                              style: TextStyle(color: colors.error),
                            ),
                            // "" = quitar la feria
                            onTap: () => Navigator.pop(sheetContext, ''),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (chosen == null || chosen == currentFairName) return;
    await _saleRepository.updateFairNameForDate(
      datePrefix,
      chosen.isEmpty ? null : chosen,
    );
    await _loadSales();
    if (!mounted) return;
    AppAlerts.showSuccess(
      context,
      chosen.isEmpty
          ? context.l10n.fairUnassigned
          : context.l10n.salesGroupedFair(chosen),
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
