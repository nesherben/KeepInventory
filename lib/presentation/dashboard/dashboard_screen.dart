import 'package:flutter/material.dart';

import '../shared/app_drawer.dart';
import '../../data/datasources/local_database_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = InventoryRepositoryImpl(LocalDatabaseDatasource());

  bool _isLoading = true;
  double _totalRevenue = 0;
  double _inventoryCost = 0;
  double _expectedRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    final revenue = await _repository.getTotalRevenue();
    final cost = await _repository.getInventoryCost();
    final expected = await _repository.getExpectedRevenue();

    setState(() {
      _totalRevenue = revenue;
      _inventoryCost = cost;
      _expectedRevenue = expected;
      _isLoading = false;
    });
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualBar() {
    // Calculamos el beneficio puro (Ingresos esperados - Lo que nos ha costado)
    final double expectedProfit = _expectedRevenue - _inventoryCost;
    final double totalPotential =
        _inventoryCost + (expectedProfit > 0 ? expectedProfit : 0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proyección del Almacén Actual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Barra de progreso nativa construida con Expanded
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  if (_inventoryCost > 0)
                    Expanded(
                      flex: (_inventoryCost * 100).toInt(),
                      child: Container(height: 20, color: Colors.orange),
                    ),
                  if (expectedProfit > 0)
                    Expanded(
                      flex: (expectedProfit * 100).toInt(),
                      child: Container(height: 20, color: Colors.blue),
                    ),
                  // Si no hay stock, mostramos una barra gris
                  if (totalPotential == 0)
                    Expanded(
                      child: Container(height: 20, color: Colors.grey[300]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Inversión (${_inventoryCost.toStringAsFixed(2)} €)'),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Beneficio neto (${expectedProfit > 0 ? expectedProfit.toStringAsFixed(2) : '0.00'} €)',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMetrics),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics, // Permite recargar tirando hacia abajo
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildMetricCard(
                    title: 'INGRESOS POR VENTAS',
                    value: '${_totalRevenue.toStringAsFixed(2)} €',
                    icon: Icons.point_of_sale,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    title: 'VALOR DEL ALMACÉN (COSTE)',
                    value: '${_inventoryCost.toStringAsFixed(2)} €',
                    icon: Icons.inventory_2,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    title: 'VENTA ESPERADA (PRECIO TOTAL)',
                    value: '${_expectedRevenue.toStringAsFixed(2)} €',
                    icon: Icons.trending_up,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  _buildVisualBar(),
                ],
              ),
            ),
    );
  }
}
