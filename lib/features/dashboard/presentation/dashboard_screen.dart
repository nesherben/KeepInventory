import 'package:flutter/material.dart';

// Rutas actualizadas a la arquitectura modular
import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_alerts.dart'; // 💡 Importamos tus AppAlerts
import '../data/datasources/dashboard_local_datasource.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../../../../core/services/github_update_service.dart';

// Importa tu paleta de colores
import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_chart.dart'; // Ajusta esta ruta si es distinta

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
        _checkForAppUpdates(); // Comprobación automática silenciosa
      });
    }
  }

  // 💡 Añadido el parámetro 'manual' para distinguir si pulsaste el botón
  Future<void> _checkForAppUpdates({bool manual = false}) async {
    try {
      if (!manual) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        // Aviso visual rápido si el usuario le dio al botón
        AppAlerts.showInfo(
          context,
          'Buscando actualizaciones en GitHub...',
          duration: const Duration(seconds: 2),
        );
      }

      if (!mounted) return;

      final updateInfo = await GithubUpdateService.checkForUpdate();

      // Si no hay actualizaciones o falló la conexión
      if (updateInfo == null) {
        if (manual && mounted) {
          AppAlerts.showSuccess(
            context,
            '¡La aplicación ya está en la última versión!',
          );
        }
        return;
      }

      if (!mounted) return;

      final String version = updateInfo['version']?.toString() ?? 'Desconocida';
      final String notes =
          updateInfo['notes']?.toString() ?? 'Sin notas de la versión.';
      final String url = updateInfo['url']?.toString() ?? '';

      if (url.isEmpty) return;

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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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

                        final success =
                            await GithubUpdateService.downloadAndInstall(url, (
                              p,
                            ) {
                              if (context.mounted) {
                                setDialogState(() => progress = p);
                              }
                            });

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext); // Cerramos el diálogo

                          if (!success && mounted) {
                            AppAlerts.showError(
                              context,
                              'Error al descargar la actualización. Revisa tu conexión a internet.',
                            );
                          }
                        }
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
      if (manual && mounted) {
        AppAlerts.showError(context, 'No se pudo conectar con el servidor.');
      }
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
    // 💡 Obtenemos el color primario actual dinámicamente desde el tema aplicado
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // Creamos un degradado elegante usando el color primario del tema actual
          colors: [
            HSLColor.fromColor(primaryColor)
                .withLightness(0.35)
                .toColor(), // Tono más oscuro para el degradado
            primaryColor, // Color primario actual del tema
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
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
            // 💡 REEMPLAZADO: Ahora es el botón de buscar actualizaciones
            IconButton(
              icon: const Icon(Icons.system_update_alt), // Icono más intuitivo
              onPressed: () => _checkForAppUpdates(manual: true),
              tooltip: 'Buscar actualizaciones',
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
