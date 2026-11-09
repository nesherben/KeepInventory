import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💡 NUEVO
import 'package:url_launcher/url_launcher.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import 'app_alerts.dart';
import 'app_ui.dart';

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
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    Widget item(
      String route,
      IconData icon,
      IconData selectedIcon,
      String label, {
      String? subtitle,
    }) => _NavItem(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      subtitle: subtitle,
      selected: currentRoute == route,
      onTap: () {
        if (currentRoute == route) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );

    Widget section(String text) =>
        SectionLabel(text, padding: const EdgeInsets.fromLTRB(28, 20, 16, 8));

    return Drawer(
      child: SafeArea(
        // El pie (autor y donación) queda abajo del todo si hay sitio; si no,
        // aparece al final al hacer scroll
        child: CustomScrollView(
          slivers: [
            SliverList.list(
              children: [
                _DrawerHeader(onTap: () => _cycleTheme(context)),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Divider(),
                ),
                section(context.l10n.navSectionMain),
                item(
                  '/',
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  context.l10n.navDashboard,
                ),
                item(
                  '/sales',
                  Icons.point_of_sale_outlined,
                  Icons.point_of_sale,
                  context.l10n.navSales,
                ),
                section(context.l10n.navSectionStockOffers),
                item(
                  '/inventory',
                  Icons.inventory_2_outlined,
                  Icons.inventory_2,
                  context.l10n.navInventory,
                ),
                item(
                  '/promotions',
                  Icons.local_offer_outlined,
                  Icons.local_offer,
                  context.l10n.navPromotions,
                ),
                item(
                  '/packs',
                  Icons.card_giftcard_outlined,
                  Icons.card_giftcard,
                  context.l10n.navPacks,
                ),
                section(context.l10n.navSectionRecords),
                item(
                  '/history',
                  Icons.history_outlined,
                  Icons.history,
                  context.l10n.navHistory,
                ),
                item(
                  '/data-management',
                  Icons.storage_outlined,
                  Icons.storage,
                  context.l10n.navDataManagement,
                  subtitle: context.l10n.navDataManagementSubtitle,
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Divider(),
                ),
                // El tutorial se abre encima de la pantalla actual (push, no replace)
                _NavItem(
                  icon: Icons.school_outlined,
                  selectedIcon: Icons.school,
                  label: context.l10n.navTutorial,
                  subtitle: context.l10n.navTutorialSubtitle,
                  selected: false,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.pushNamed('/tutorial');
                  },
                ),
              ],
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _DrawerFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pie del menú: autor, enlace al código y donación por PayPal.
class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  static const _authorName = 'Néstor';
  static final _donateUrl = Uri.parse('https://www.paypal.me/nestor8299');
  static final _repoUrl = Uri.parse(
    'https://github.com/nesherben/KeepInventory',
  );

  Future<void> _open(BuildContext context, Uri url) async {
    var opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && context.mounted) {
      AppAlerts.showError(context, context.l10n.linkOpenError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, AppSpacing.lg, 16, AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.drawerMadeBy(_authorName),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.drawerFreeApp,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: () => _open(context, _donateUrl),
              icon: const Icon(Icons.coffee_outlined, size: 18),
              label: Text(context.l10n.drawerDonate),
            ),
            TextButton.icon(
              onPressed: () => _open(context, _repoUrl),
              icon: const Icon(Icons.code, size: 18),
              label: Text(context.l10n.drawerSourceCode),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera: icono de la app, nombre, versión y subtítulo.
/// 💡 Huevo de pascua: tocarla cambia el color del tema.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.storefront,
                  color: colors.onPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'KeepInventory',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            final version = snapshot.data?.version;
                            if (version == null || version.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v$version',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.drawerSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada del menú: píldora redondeada; la pantalla actual va resaltada.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? colors.primary : colors.onSurface,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
