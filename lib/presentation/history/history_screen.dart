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
    // Ordenar del más reciente al más antiguo
    sales.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }

  // Lógica para anular un ticket y devolver el stock
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
              Navigator.pop(context); // Cierra el diálogo

              // Ejecutamos la devolución en el repositorio
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

  // Formatear la fecha para la feria (Ej: Día 14 - 18:30)
  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month a las $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tickets'),
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
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.receipt_long, color: Colors.white),
                    ),
                    title: Text(
                      'Ticket #${sale.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                            // BOTÓN DE ANULAR / DEVOLVER VENTA
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
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  icon: const Icon(Icons.undo, size: 18),
                                  label: const Text('Anular y Devolver Venta'),
                                  onPressed: () => _refundSale(sale),
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
    );
  }
}
