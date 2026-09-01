import 'package:flutter/material.dart';

// Rutas actualizadas a la arquitectura modular
import '../../../core/shared_widgets/app_drawer.dart';
import '../data/datasources/dashboard_local_datasource.dart';
import '../data/repositories/dashboard_repository_impl.dart';

import '../../../../core/services/github_update_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Instanciamos el nuevo repositorio optimizado
  final _dashboardRepository = DashboardRepositoryImpl(
    DashboardLocalDatasource(),
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double? _startX;
  double? _startY;

  bool _isLoading = true;
  bool _isPrivacyModeEnabled = false; // Estado del modo privacidad

  double _totalRevenue = 0;
  double _inventoryCost = 0;
  double _expectedRevenue = 0;
  double _actualNetProfit = 0;
  Map<String, double> _dailySales = {};
  Map<String, double> _dailyNetProfits = {};

  static bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();

    // 💡 2. COMPROBACIÓN: Solo ejecutamos el update si la bandera está en false
    if (!_hasCheckedForUpdate) {
      _hasCheckedForUpdate =
          true; // La marcamos como vista para el resto de la sesión

      // Es recomendable meter los popups/dialogos en un PostFrameCallback
      // para que Flutter termine de pintar la pantalla antes de saltar el aviso
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForAppUpdates();
      });
    }
  }

  // Comprobación automática de actualizaciones al arrancar
  Future<void> _checkForAppUpdates() async {
    // Esperamos un par de segundos a que cargue la app para no saturar el inicio
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final updateInfo = await GithubUpdateService.checkForUpdate();
    if (updateInfo == null || !mounted) return;

    // Si hay update, mostramos el diálogo de actualización
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        double progress = 0.0;
        bool isDownloading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                '¡Nueva versión v${updateInfo['version']} disponible!',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hay una actualización lista para instalar con mejoras y correcciones:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Text(
                        updateInfo['notes'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isDownloading) ...[
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Descargando... ${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Más tarde'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() => isDownloading = true);
                      await GithubUpdateService.downloadAndInstall(
                        updateInfo['url'],
                        (p) {
                          setDialogState(() => progress = p);
                        },
                      );
                    },
                    child: const Text('Actualizar ahora'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      // Llamadas actualizadas al nuevo repositorio
      final revenue = await _dashboardRepository.getTotalRevenue();
      final cost = await _dashboardRepository.getInventoryCost();
      final expected = await _dashboardRepository.getExpectedRevenue();
      final netProfit = await _dashboardRepository.getActualNetProfit();
      final dailySales = await _dashboardRepository.getDailySales();
      final dailyNetProfits = await _dashboardRepository.getDailyNetProfits();

      if (!mounted) return;
      setState(() {
        _totalRevenue = revenue;
        _inventoryCost = cost;
        _expectedRevenue = expected;
        _actualNetProfit = netProfit;
        _dailySales = dailySales;
        _dailyNetProfits = dailyNetProfits;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openFullScreenChart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenChartScreen(
          dailySales: _dailySales,
          dailyNetProfits: _dailyNetProfits,
          isPrivacyModeEnabled: _isPrivacyModeEnabled, // Pasamos el modo privacidad al gráfico también por seguridad
        ),
      ),
    );
  }

  // Formateador inteligente para censurar datos si el modo privacidad está activo
  String _formatCurrency(double amount) {
    if (_isPrivacyModeEnabled) {
      return '•••••• €';
    }
    return '${amount.toStringAsFixed(2)} €';
  }

  // Tarjeta de métricas secundaria
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
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
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

  // Botón de acceso al balance y gráfico
  Widget _buildChartButton() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _openFullScreenChart,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: Colors.amber.shade900,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Balance por Ferias y Días',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ver gráfico con barra y punto neto',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de recaudación principal
  Widget _buildMainCard(bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade900, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              bottom: -25,
              child: Icon(
                Icons.point_of_sale,
                size: 130,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isWideScreen ? 28 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white70,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'CAJA GENERAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _formatCurrency(_totalRevenue), // Aplicando modo privacidad
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWideScreen ? 40 : 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white60, size: 13),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Balance acumulado de ferias y ventas directas',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= 600;

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
          title: const Text('Panel de Control'),
          elevation: 0,
          actions: [
            // Botón de Modo Privacidad en la barra superior
            IconButton(
              icon: Icon(
                _isPrivacyModeEnabled ? Icons.visibility_off : Icons.visibility,
                color: _isPrivacyModeEnabled ? Colors.amberAccent : null,
              ),
              onPressed: () {
                setState(() {
                  _isPrivacyModeEnabled = !_isPrivacyModeEnabled;
                });
              },
              tooltip: _isPrivacyModeEnabled
                  ? 'Desactivar modo privacidad'
                  : 'Activar modo privacidad',
            ),
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
                  padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
                  children: [
                    if (isWideScreen) ...[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildMainCard(true)),
                                  const SizedBox(height: 12),
                                  _buildChartButton(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'COSTE ALMACÉN',
                                      value: _formatCurrency(_inventoryCost),
                                      icon: Icons.inventory_2_outlined,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'VALOR VENTA',
                                      value: _formatCurrency(_expectedRevenue),
                                      icon: Icons.trending_up,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'BENEFICIO NETO REAL',
                                      value: _formatCurrency(_actualNetProfit),
                                      icon: Icons.savings_outlined,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _buildMainCard(false),
                      const SizedBox(height: 16),
                      _buildChartButton(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'COSTE ALMACÉN',
                              value: _formatCurrency(_inventoryCost),
                              icon: Icons.inventory_2_outlined,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'VALOR VENTA',
                              value: _formatCurrency(_expectedRevenue),
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
                              title: 'BENEFICIO NETO REAL',
                              value: _formatCurrency(_actualNetProfit),
                              icon: Icons.savings_outlined,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// PANTALLA COMPLETA / PANTALLA ANCHA: Gráfico y Listado con Privacidad
// --------------------------------------------------------------------------
class FullScreenChartScreen extends StatefulWidget {
  final Map<String, double> dailySales;
  final Map<String, double> dailyNetProfits;
  final bool isPrivacyModeEnabled;

  const FullScreenChartScreen({
    super.key,
    required this.dailySales,
    required this.dailyNetProfits,
    required this.isPrivacyModeEnabled,
  });

  @override
  State<FullScreenChartScreen> createState() => _FullScreenChartScreenState();
}

class _FullScreenChartScreenState extends State<FullScreenChartScreen> {
  late bool _privacyActive;

  @override
  void initState() {
    super.initState();
    _privacyActive = widget.isPrivacyModeEnabled;
  }

  String _formatCurrency(double amount) {
    if (_privacyActive) return '•••••• €';
    return '${amount.toStringAsFixed(2)} €';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= 600;

    double maxVal = 0.0;
    for (var val in widget.dailySales.values) {
      if (val > maxVal) maxVal = val;
    }
    for (var val in widget.dailyNetProfits.values) {
      if (val > maxVal) maxVal = val;
    }

    final double totalSales = widget.dailySales.values.fold(
      0.0,
      (sum, v) => sum + v,
    );
    final double totalNet = widget.dailyNetProfits.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    final Set<String> allKeys = {
      ...widget.dailySales.keys,
      ...widget.dailyNetProfits.keys,
    };
    final List<String> sortedKeys = allKeys.toList();

    Widget buildChartContent() {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
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
          children: sortedKeys.map((key) {
            final revenue = widget.dailySales[key] ?? 0.0;
            final net = widget.dailyNetProfits[key] ?? 0.0;

            final revFactor = maxVal == 0 ? 0.0 : revenue / maxVal;
            final netFactor = maxVal == 0 ? 0.0 : net / maxVal;

            final parts = key.split('-');
            final shortLabel = parts.length == 3
                ? '${parts[2]}/${parts[1]}'
                : (key.length > 6 ? '${key.substring(0, 5)}..' : key);

            final isFair = parts.length != 3;

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _privacyActive ? '••€' : '${revenue.toStringAsFixed(0)}€',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: revFactor,
                            child: Container(
                              width: 16,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isFair
                                    ? Colors.amber.shade700
                                    : Theme.of(context).primaryColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(0, 1.0 - (2.0 * netFactor)),
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green.shade900,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
      );
    }

    Widget buildHeaderAndLegend() {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'TOTAL INGRESOS',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalSales),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text(
                      'TOTAL NETO',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalNet),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Días sueltos',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ferias',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Beneficio Neto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildListView() {
      return ListView.separated(
        itemCount: sortedKeys.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final key = sortedKeys[sortedKeys.length - 1 - index];
          final revenue = widget.dailySales[key] ?? 0.0;
          final net = widget.dailyNetProfits[key] ?? 0.0;

          final parts = key.split('-');
          final isDate = parts.length == 3;
          final formattedTitle = isDate
              ? 'Día: ${parts[2]}/${parts[1]}/${parts[0]}'
              : '🎪 Feria: $key';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (isDate ? Theme.of(context).primaryColor : Colors.amber)
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              'Ingresos: ${_formatCurrency(revenue)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              'Neto: ${_formatCurrency(net)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green,
              ),
            ),
          );
        },
      );
    }

    return Listener(
      onPointerDown: (event) {
        // Placeholder para future implementation
      },
      onPointerMove: (event) {
        // Placeholder para future implementation
      },
      onPointerUp: (_) {
        // Placeholder para future implementation
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Balance Detallado'),
          actions: [
            // Botón de privacidad también en el detalle del gráfico
            IconButton(
              icon: Icon(
                _privacyActive ? Icons.visibility_off : Icons.visibility,
                color: _privacyActive ? Colors.amberAccent : null,
              ),
              onPressed: () {
                setState(() {
                  _privacyActive = !_privacyActive;
                });
              },
              tooltip: _privacyActive
                  ? 'Desactivar privacidad'
                  : 'Activar privacidad',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: sortedKeys.isEmpty
            ? const Center(
                child: Text(
                  'Aún no hay ventas para mostrar.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : isWideScreen
            ? Row(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: buildListView(),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Column(
                      children: [
                        buildHeaderAndLegend(),
                        Expanded(child: buildChartContent()),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  buildHeaderAndLegend(),
                  Expanded(flex: 3, child: buildChartContent()),
                  Expanded(flex: 2, child: buildListView()),
                ],
              ),
      ),
    );
  }
}
