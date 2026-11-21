import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../services/app_preferences.dart';
import 'app_ui.dart';
import 'coach_marks.dart';

/// Navegador global: la barra lateral vive fuera del `Navigator` y navega con él.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Ruta con nombre que se está viendo (las ventanas y hojas no cuentan).
final ValueNotifier<String?> appCurrentRoute = ValueNotifier(null);

final NavigatorObserver appRouteObserver = _RouteObserver();

class _RouteObserver extends NavigatorObserver {
  void _set(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name == appCurrentRoute.value) return;
    // Tras el frame: el primer push ocurre mientras se construye el árbol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appCurrentRoute.value = name;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    CoachMarks.dismissAll();
    _set(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _set(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    CoachMarks.dismissAll();
    _set(previousRoute);
  }
}

/// Secciones de la barra, en el mismo orden que el menú lateral.
class _RailItem {
  const _RailItem(this.route, this.icon, this.selectedIcon);

  final String route;
  final IconData icon;
  final IconData selectedIcon;
}

const _railItems = [
  _RailItem('/', Icons.home_outlined, Icons.home),
  _RailItem('/sales', Icons.point_of_sale_outlined, Icons.point_of_sale),
  _RailItem('/history', Icons.receipt_long_outlined, Icons.receipt_long),
  _RailItem('/inventory', Icons.inventory_2_outlined, Icons.inventory_2),
  _RailItem('/promotions', Icons.local_offer_outlined, Icons.local_offer),
  _RailItem('/packs', Icons.card_giftcard_outlined, Icons.card_giftcard),
  _RailItem('/changes', Icons.history, Icons.history),
  _RailItem('/data-management', Icons.storage_outlined, Icons.storage),
];

/// Anchos de la barra: plegada (solo iconos) y desplegada (con nombres).
const double kRailCollapsedWidth = 72;
const double kRailExpandedWidth = 232;

/// ¿Cabe una barra lateral fija? Solo en tablets y con ancho de sobra.
bool railFits(Size size) => size.width >= 840 && size.shortestSide >= 600;

/// Envoltorio de toda la app: en tablet añade, a la izquierda, una barra fija
/// con los iconos de las secciones (plegable a solo iconos o con nombres). El
/// contenido recibe un `MediaQuery` más estrecho para que las pantallas se
/// maqueten con el ancho que de verdad tienen.
///
/// La estructura es siempre la misma (fila con barra + contenido) para que el
/// `Navigator` no pierda su estado al girar el dispositivo.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _hiddenOn = {'/tutorial', '/first-run'};

  /// ¿Se está mostrando ahora la barra lateral?
  static bool railVisible = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final fits = railFits(media.size);
    return ValueListenableBuilder<String?>(
      valueListenable: appCurrentRoute,
      builder: (context, route, _) {
        final show = fits && route != null && !_hiddenOn.contains(route);
        railVisible = show;
        return ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.railExpanded,
          builder: (context, expanded, _) {
            final width = !show
                ? 0.0
                : (expanded ? kRailExpandedWidth : kRailCollapsedWidth);
            final divider = show ? 1.0 : 0.0;
            return Row(
              children: [
                SizedBox(
                  width: width,
                  // Overlay propio: los tooltips de la barra lo necesitan
                  // (queda fuera del Navigator)
                  child: show
                      ? Overlay(
                          initialEntries: [
                            OverlayEntry(builder: (_) => const _SideRail()),
                          ],
                        )
                      : null,
                ),
                SizedBox(
                  width: divider,
                  child: show ? const VerticalDivider(width: 1) : null,
                ),
                Expanded(
                  child: MediaQuery(
                    data: media.copyWith(
                      size: Size(
                        media.size.width - width - divider,
                        media.size.height,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail();

  String _label(BuildContext context, String route) {
    final l10n = context.l10n;
    return switch (route) {
      '/' => l10n.navDashboard,
      '/sales' => l10n.navSales,
      '/history' => l10n.navHistory,
      '/inventory' => l10n.navInventory,
      '/promotions' => l10n.navPromotions,
      '/packs' => l10n.navPacks,
      '/changes' => l10n.navHistoryChanges,
      _ => l10n.navDataManagement,
    };
  }

  void _go(String route) {
    if (appCurrentRoute.value == route) return;
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        right: false,
        child: ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.railExpanded,
          builder: (context, expanded, _) => ValueListenableBuilder<String?>(
            valueListenable: appCurrentRoute,
            builder: (context, current, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: expanded
                        ? Alignment.centerRight
                        : Alignment.center,
                    child: IconButton(
                      tooltip: expanded
                          ? context.l10n.railCollapse
                          : context.l10n.railExpand,
                      icon: Icon(
                        expanded ? Icons.menu_open : Icons.menu,
                        color: colors.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          AppPreferences.setRailExpanded(!expanded),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    children: [
                      for (final item in _railItems)
                        _RailButton(
                          item: item,
                          label: _label(context, item.route),
                          selected: current == item.route,
                          expanded: expanded,
                          onTap: () => _go(item.route),
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

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.item,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _RailItem item;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = selected ? colors.primary : colors.onSurfaceVariant;
    final button = Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: expanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (expanded) const SizedBox(width: AppSpacing.md),
              Icon(selected ? item.selectedIcon : item.icon, color: tint),
              if (expanded) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? colors.primary : colors.onSurface,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        // Plegada solo hay icono: el tooltip dice a dónde lleva
        child: expanded ? button : Tooltip(message: label, child: button),
      ),
    );
  }
}
