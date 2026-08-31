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

  // NUEVO: Navega a la pantalla completa del gráfico
  Future<void> _openFullScreenChart() async {
    // Mostramos un indicador de carga mientras calculamos los datos si fueran muchos
    final dailySales = await _repository.getDailySales();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenChartScreen(dailySales: dailySales),
      ),
    );
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
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 28),
            onPressed: _openFullScreenChart,
            tooltip: 'Ver gráfico diario',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
            tooltip: 'Refrescar datos',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics,
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

// --------------------------------------------------------------------------
// NUEVA PANTALLA COMPLETA: Gráfico de Ventas Diarias
// --------------------------------------------------------------------------
class FullScreenChartScreen extends StatelessWidget {
  final Map<String, double> dailySales;

  const FullScreenChartScreen({super.key, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    // Pre-cálculos para la gráfica
    final double maxSale = dailySales.isEmpty
        ? 0.0
        : dailySales.values.reduce((a, b) => a > b ? a : b);
    final double totalSales = dailySales.values.fold(
      0.0,
      (sum, value) => sum + value,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Balance por Días')),
      body: dailySales.isEmpty
          ? const Center(
              child: Text(
                'Aún no hay ventas para mostrar.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // ZONA 1: Total general destacado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  child: Column(
                    children: [
                      const Text(
                        'Total Recaudado en Feria',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalSales.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ZONA 2: Gráfico de barras visual
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.only(
                      top: 24.0,
                      bottom: 12.0,
                      left: 8.0,
                      right: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: dailySales.entries.map((entry) {
                        final total = entry.value;
                        final heightFactor = maxSale == 0
                            ? 0.0
                            : total / maxSale;

                        // Formato de fecha para la barra (Ej: 14/10)
                        final parts = entry.key.split('-');
                        final shortDay = parts.length == 3
                            ? '${parts[2]}/${parts[1]}'
                            : entry.key;

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${total.toStringAsFixed(0)}€',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: heightFactor,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(8),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                shortDay,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // ZONA 3: Desglose en formato lista
                Expanded(
                  flex: 2,
                  child: ListView.separated(
                    itemCount: dailySales.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // Invertimos la lista para mostrar el día más reciente arriba
                      final key = dailySales.keys.elementAt(
                        dailySales.length - 1 - index,
                      );
                      final value = dailySales[key]!;

                      final parts = key.split('-');
                      final formattedDate = parts.length == 3
                          ? '${parts[2]}/${parts[1]}/${parts[0]}'
                          : key;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor
                              .withValues(alpha: 0.1),
                          child: Icon(
                            Icons.calendar_month,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          'Caja del $formattedDate',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Text(
                          '${value.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
