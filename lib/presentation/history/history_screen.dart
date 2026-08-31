import 'package:flutter/material.dart';

import '../shared/app_drawer.dart';
import '../../domain/entities/sale.dart';
import '../../data/datasources/local_database_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = InventoryRepositoryImpl(LocalDatabaseDatasource());
  bool _isLoading = true;
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final sales = await _repository.getSales();
    sales.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }

  Future<void> _refundSale(Sale sale) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular y Devolver Venta'),
        content: Text(
          '¿Estás seguro de anular el Ticket #${sale.id}?\n\n'
          'Se restará el importe de la caja y se devolverán las unidades al stock del inventario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _repository.refundSale(sale);
              await _loadSales();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ticket anulado y stock devuelto correctamente.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Anular Venta',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo inteligente para elegir una feria existente o escribir una nueva
  void _showAssignFairDialog(String datePrefix, String currentFairName) async {
    final List<String> existingFairs = await _repository.getAvailableFairs();

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

                await _repository.updateFairNameForDate(
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
    // Agrupar ventas: Por Feria si la tiene, si no por Fecha (DD/MM/YYYY)
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

    return Scaffold(
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
                            color: isFair ? Colors.amber.shade900 : Colors.teal,
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
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                        ...sale.items.map((item) {
                                          return ListTile(
                                            dense: true,
                                            title: Text(
                                              '${item.quantity}x ${item.productName}',
                                            ),
                                            trailing: Text(
                                              '${(item.quantity * item.historicalPrice).toStringAsFixed(2)} €',
                                            ),
                                          );
                                        }),
                                        const Divider(height: 16),
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
                                                'Anular y Devolver Venta',
                                              ),
                                              onPressed: () =>
                                                  _refundSale(sale),
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
    );
  }
}
