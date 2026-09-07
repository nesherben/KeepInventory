import 'package:flutter/material.dart';

// Rutas actualizadas a la arquitectura modular
import '../../../core/shared_widgets/app_drawer.dart';
import '../data/datasources/dashboard_local_datasource.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../../../../core/services/github_update_service.dart';

// Importa tu paleta de colores
import '../../../core/theme/app_colors.dart'; // Ajusta esta ruta si es distinta

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardRepository = DashboardRepositoryImpl(
    DashboardLocalDatasource(),
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 💡 Restauradas las variables para controlar el gesto táctil
  double? _startX;
  double? _startY;

  bool _isLoading = true;
  bool _isPrivacyModeEnabled = false;

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
    _loadMetrics();

    if (!_hasCheckedForUpdate) {
      _hasCheckedForUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForAppUpdates();
      });
    }
  }

  Future<void> _checkForAppUpdates() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final updateInfo = await GithubUpdateService.checkForUpdate();
      if (updateInfo == null || !mounted) return;

      final String version = updateInfo['version']?.toString() ?? 'Desconocida';
      final String notes =
          updateInfo['notes']?.toString() ?? 'Sin notas de la versión.';
      final String url = updateInfo['url']?.toString() ?? '';

      if (url.isEmpty) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          double progress = 0.0;
          bool isDownloading = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('¡Nueva versión v$version disponible!'),
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
                          notes,
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
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Más tarde'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setDialogState(() => isDownloading = true);

                        await GithubUpdateService.downloadAndInstall(url, (p) {
                          if (context.mounted) {
                            setDialogState(() => progress = p);
                          }
                        });
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
    } catch (e) {
      print("❌ Error en _checkForAppUpdates: $e");
    }
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
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
          isPrivacyModeEnabled: _isPrivacyModeEnabled,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (_isPrivacyModeEnabled) {
      return '•••••• €';
    }
    return '${amount.toStringAsFixed(2)} €';
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(context).colorScheme.secondary
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Balance por Ferias y Días',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ver gráfico de barras y beneficio neto',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
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
                    _formatCurrency(_totalRevenue),
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

    // 💡 Restaurado el Listener para que al deslizar se abra el menú lateral en el Dashboard
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
            IconButton(
              icon: Icon(
                _isPrivacyModeEnabled ? Icons.visibility_off : Icons.visibility,
                color: _isPrivacyModeEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : null,
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
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'VALOR VENTA',
                                      value: _formatCurrency(_expectedRevenue),
                                      icon: Icons.trending_up,
                                      color: AppColors.info,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'BENEFICIO NETO REAL',
                                      value: _formatCurrency(_actualNetProfit),
                                      icon: Icons.savings_outlined,
                                      color: AppColors.success,
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
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'VALOR VENTA',
                              value: _formatCurrency(_expectedRevenue),
                              icon: Icons.trending_up,
                              color: AppColors.info,
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
                              color: AppColors.success,
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

    final cardBgColor = Theme.of(context).cardColor;

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
          color: cardBgColor,
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

            final barColor = isFair
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary;

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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barHeight = constraints.maxHeight * revFactor;
                        final dotBottom = constraints.maxHeight * netFactor;

                        return Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: barHeight,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: dotBottom > 0 ? dotBottom - 6 : 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cardBgColor,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .shadow
                                          .withValues(alpha: 0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shortLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'TOTAL INGRESOS',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalSales),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Column(
                  children: [
                    Text(
                      'TOTAL NETO',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalNet),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
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
              vertical: 12.0,
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(3),
                      ),
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBgColor, width: 1.5),
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
                  (isDate
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary)
                      .withValues(alpha: 0.15),
              child: Icon(
                isDate ? Icons.calendar_month : Icons.store,
                color: isDate
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Detallado'),
        actions: [
          IconButton(
            icon: Icon(
              _privacyActive ? Icons.visibility_off : Icons.visibility,
              color: _privacyActive
                  ? Theme.of(context).colorScheme.secondary
                  : null,
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
          ? Center(
              child: Text(
                'Aún no hay ventas para mostrar.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : isWideScreen
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    color: Theme.of(context).cardColor,
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
    );
  }
}
