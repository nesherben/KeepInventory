import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💡 NUEVO

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../theme/app_colors.dart';
import 'app_alerts.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Lista de colores del huevo de pascua (guardamos un identificador único en 'key')
  static final List<Map<String, dynamic>> _themeColors = [
    {'color': null, 'key': 'default'},
    {'color': Colors.blue, 'key': 'blue'},
    {'color': Colors.teal, 'key': 'teal'},
    {'color': Colors.deepPurple, 'key': 'purple'},
    {'color': Colors.redAccent, 'key': 'red'},
    {'color': Colors.orangeAccent, 'key': 'orange'},
  ];

  static final ValueNotifier<Color?> customThemeNotifier =
      ValueNotifier<Color?>(null);
  static int _currentColorIndex = 0;

  // 💡 NUEVO: Método para cargar el tema guardado al iniciar la app
  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('selected_theme_key') ?? 'default';

    // Buscamos qué índice corresponde a la clave guardada
    final index = _themeColors.indexWhere((item) => item['key'] == savedKey);
    if (index != -1) {
      _currentColorIndex = index;
      customThemeNotifier.value =
          _themeColors[_currentColorIndex]['color'] as Color?;
    }
  }

  void _cycleTheme(BuildContext context) async {
    _currentColorIndex = (_currentColorIndex + 1) % _themeColors.length;
    final selectedTheme = _themeColors[_currentColorIndex];

    // Cambiamos el color en caliente
    customThemeNotifier.value = selectedTheme['color'] as Color?;
    final themeLabel = _themeName(context, selectedTheme['key']);
    final message = context.l10n.themeChanged(themeLabel);

    // Guardamos la preferencia en el dispositivo de forma permanente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme_key', selectedTheme['key']);
    if (!context.mounted) return;

    AppAlerts.showSuccess(
      context,
      message,
      duration: const Duration(seconds: 2),
    );
  }

  static String _themeName(BuildContext context, String key) => switch (key) {
    'blue' => context.l10n.themeNameBlue,
    'teal' => context.l10n.themeNameGreen,
    'purple' => context.l10n.themeNamePurple,
    'red' => context.l10n.themeNameRed,
    'orange' => context.l10n.themeNameOrange,
    _ => context.l10n.themeNameDefault,
  };

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            // 💡 HUEVO DE PASCUA: GestureDetector en todo el contenedor de la cabecera
            child: InkWell(
              onTap: () => _cycleTheme(context),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.transparent,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'KeepInventory',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            final version = snapshot.hasData
                                ? snapshot.data!.version
                                : '';
                            if (version.isEmpty) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                'v$version',
                                style: const TextStyle(
                                  color: AppColors.onPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.drawerSubtitle,
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- SECCIÓN 1: PRINCIPAL Y VENTAS ---
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.navSectionMain,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSubtle,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard_outlined, color: iconColor),
            title: Text(context.l10n.navDashboard),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: Icon(Icons.point_of_sale_outlined, color: iconColor),
            title: Text(context.l10n.navSales),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/sales');
            },
          ),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- SECCIÓN 2: ALMACÉN Y CATÁLOGO ---
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.l10n.navSectionStockOffers,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSubtle,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.inventory_2_outlined, color: iconColor),
            title: Text(context.l10n.navInventory),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/inventory');
            },
          ),
          ListTile(
            leading: Icon(Icons.local_offer_outlined, color: iconColor),
            title: Text(context.l10n.navPromotions),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/promotions');
            },
          ),
          ListTile(
            leading: Icon(Icons.card_giftcard, color: iconColor),
            title: Text(context.l10n.navPacks),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/packs');
            },
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- SECCIÓN 3: HISTORIAL Y REGISTROS ---
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.l10n.navSectionRecords,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSubtle,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history_outlined, color: iconColor),
            title: Text(context.l10n.navHistory),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/history');
            },
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              Icons.storage_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(context.l10n.navDataManagement),
            subtitle: Text(context.l10n.navDataManagementSubtitle),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/data-management');
            },
          ),
        ],
      ),
    );
  }
}
