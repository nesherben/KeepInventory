import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../services/app_preferences.dart';
import 'app_drawer.dart';
import 'coach_marks.dart';

/// Navegador global: la barra lateral vive fuera del `Navigator` y navega con él.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Ruta con nombre que se está viendo (las ventanas y hojas no cuentan).
final ValueNotifier<String?> appCurrentRoute = ValueNotifier(null);

final NavigatorObserver appRouteObserver = _RouteObserver();

class _RouteObserver extends NavigatorObserver {
  /// Ruta con nombre que había antes de abrir el tutorial (que oculta la barra).
  String? _beforeTutorial;

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
    if (route.settings.name == '/tutorial') {
      _beforeTutorial = appCurrentRoute.value;
    }
    _set(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _set(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    CoachMarks.dismissAll();
    if (route.settings.name == '/tutorial' &&
        previousRoute?.settings.name == null &&
        _beforeTutorial != null) {
      // La pantalla de debajo no tiene nombre: se recupera la anterior
      final restore = _beforeTutorial!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appCurrentRoute.value = restore;
      });
      return;
    }
    _set(previousRoute);
  }
}

/// ¿Hay barra lateral a la vista? Con ella, el menú clásico sobra: la barra es
/// ese mismo menú plegado a iconos.
class RailScope extends InheritedWidget {
  const RailScope({super.key, required this.visible, required super.child});

  final bool visible;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RailScope>()?.visible ?? false;

  @override
  bool updateShouldNotify(RailScope old) => visible != old.visible;
}

/// Menú lateral clásico de una pantalla: no existe cuando hay barra lateral
/// (tampoco su botón ☰; la barra se pliega y despliega con su propio botón).
Widget? appDrawer(BuildContext context) =>
    RailScope.of(context) ? null : const AppDrawer();

/// Anchos de la barra: plegada (solo iconos) y desplegada (como el menú del móvil).
const double kRailCollapsedWidth = 72;
const double kRailExpandedWidth = 304;

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
                    child: RailScope(visible: show, child: child),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        right: false,
        child: ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.railExpanded,
          builder: (context, expanded, _) => AppMenu(
            inRail: true,
            collapsed: !expanded,
            toggle: IconButton(
              tooltip: expanded
                  ? context.l10n.railCollapse
                  : context.l10n.railExpand,
              icon: Icon(
                expanded ? Icons.menu_open : Icons.menu,
                color: colors.onSurfaceVariant,
              ),
              onPressed: () => AppPreferences.setRailExpanded(!expanded),
            ),
          ),
        ),
      ),
    );
  }
}
