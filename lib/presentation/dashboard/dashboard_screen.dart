import 'package:flutter/material.dart';

import '../shared/app_drawer.dart';
import '../history/history_screen.dart';
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
  Map<String, double> _dailySales = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      final revenue = await _repository.getTotalRevenue();
      final cost = await _repository.getInventoryCost();
      final expected = await _repository.getExpectedRevenue();
      final dailySales = await _repository.getDailySales();

      setState(() {
        _totalRevenue = revenue;
        _inventoryCost = cost;
        _expectedRevenue = expected;
        _dailySales = dailySales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openFullScreenChart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenChartScreen(dailySales: _dailySales),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double expectedProfit = _expectedRevenue - _inventoryCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
            tooltip: 'Actualizar datos',
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
                  // 1. TARJETA PRINCIPAL (CAJA / RECAUDACIÓN)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade800, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'RECAUDACIÓN TOTAL (CAJA)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.point_of_sale,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_totalRevenue.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Balance acumulado de ferias y ventas directas',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. TARJETAS SECUNDARIAS EN PARRILLA (GRID)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'COSTE ALMACÉN',
                          value: '${_inventoryCost.toStringAsFixed(2)} €',
                          icon: Icons.inventory_2_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'VALOR VENTA',
                          value: '${_expectedRevenue.toStringAsFixed(2)} €',
                          icon: Icons.trending_up,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'BENEFICIO NETO EST.',
                          value:
                              '${expectedProfit > 0 ? expectedProfit.toStringAsFixed(2) : '0.00'} €',
                          icon: Icons.savings_outlined,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. ACCESO RÁPIDO AL GRÁFICO / BALANCE
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: _openFullScreenChart,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.bar_chart,
                                color: Colors.amber.shade900,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Balance por Ferias y Días',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Toca para ver el gráfico detallado de ventas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// PANTALLA COMPLETA: Gráfico de Ferias y Días
// --------------------------------------------------------------------------
class FullScreenChartScreen extends StatelessWidget {
  final Map<String, double> dailySales;

  const FullScreenChartScreen({super.key, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    final double maxSale = dailySales.isEmpty
        ? 0.0
        : dailySales.values.reduce((a, b) => a > b ? a : b);
    final double totalSales = dailySales.values.fold(
      0.0,
      (sum, value) => sum + value,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Balance por Ferias y Días')),
      body: dailySales.isEmpty
          ? const Center(
              child: Text(
                'Aún no hay ventas para mostrar.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor
                        .withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL RECAUDADO GLOBAL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalSales.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 36,
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
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
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

                        final rawKey = entry.key;
                        final parts = rawKey.split('-');
                        final shortLabel = parts.length == 3
                            ? '${parts[2]}/${parts[1]}'
                            : (rawKey.length > 8
                                  ? '${rawKey.substring(0, 6)}..'
                                  : rawKey);

                        final isFair = parts.length != 3;

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${total.toStringAsFixed(0)}€',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
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
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFair
                                            ? Colors.amber.shade700
                                            : Theme.of(context).primaryColor,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                shortLabel,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
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
                      final key = dailySales.keys.elementAt(
                        dailySales.length - 1 - index,
                      );
                      final value = dailySales[key]!;

                      final parts = key.split('-');
                      final isDate = parts.length == 3;
                      final formattedTitle = isDate
                          ? 'Día: ${parts[2]}/${parts[1]}/${parts[0]}'
                          : '🎪 Feria: $key';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (isDate
                                      ? Theme.of(context).primaryColor
                                      : Colors.amber)
                                  .withValues(alpha: 0.15),
                          child: Icon(
                            isDate ? Icons.calendar_month : Icons.store,
                            color: isDate
                                ? Theme.of(context).primaryColor
                                : Colors.amber.shade900,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          formattedTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Text(
                          '${value.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
