import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import 'app_ui.dart';

/// Margen inferior para lo que se pinta pegado al borde de abajo: lo que
/// ocupe más, el teclado o la barra de navegación de Android (con la app
/// dibujada de borde a borde, la barra puede tapar los botones).
double bottomSafeInset(BuildContext context) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  final navBar = MediaQuery.viewPaddingOf(context).bottom;
  return keyboard > navBar ? keyboard : navBar;
}

/// Cómo se presenta un formulario según la pantalla.
enum AdaptiveFormMode {
  /// Móvil: panel desde abajo a pantalla completa, con píldora para cerrar.
  sheet,

  /// Tablet apaisada: panel lateral desde la derecha (la lista sigue a la
  /// vista a la izquierda).
  side,

  /// Tablet vertical: diálogo centrado con letra y campos más grandes.
  dialog,
}

/// Formularios adaptados al dispositivo (ver [AdaptiveFormMode]).
abstract final class AdaptiveForm {
  /// Por debajo de este ancho: panel desde abajo.
  static const double sheetBreakpoint = 600;

  /// A partir de este ancho y en horizontal: panel lateral.
  static const double sideBreakpoint = 900;
  static const double sideWidth = 480;

  static AdaptiveFormMode modeOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < sheetBreakpoint) return AdaptiveFormMode.sheet;
    if (size.width >= sideBreakpoint && size.width > size.height) {
      return AdaptiveFormMode.side;
    }
    return AdaptiveFormMode.dialog;
  }

  static bool isSheet(BuildContext context) =>
      modeOf(context) == AdaptiveFormMode.sheet;

  /// Paneles (móvil y lateral): campos en una sola columna.
  static bool isSingleColumn(BuildContext context) =>
      modeOf(context) != AdaptiveFormMode.dialog;

  /// Abre [builder] como panel inferior, panel lateral o diálogo.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    switch (modeOf(context)) {
      case AdaptiveFormMode.sheet:
        return showModalBottomSheet<T>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: builder,
        );
      case AdaptiveFormMode.side:
        return showGeneralDialog<T>(
          context: context,
          barrierDismissible: true,
          barrierLabel: MaterialLocalizations.of(context)
              .modalBarrierDismissLabel,
          barrierColor: Colors.black26,
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, _, _) => Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: sideWidth,
              height: double.infinity,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.xl),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(left: false, child: builder(context)),
              ),
            ),
          ),
          transitionBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      case AdaptiveFormMode.dialog:
        return showDialog<T>(context: context, builder: builder);
    }
  }
}

/// Estructura común de un formulario: título, contenido con scroll y
/// acciones (Cancelar / Guardar). Se pinta según [AdaptiveForm.modeOf].
class AdaptiveFormScaffold extends StatelessWidget {
  const AdaptiveFormScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.dialogWidth = 600,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double dialogWidth;

  @override
  Widget build(BuildContext context) {
    return switch (AdaptiveForm.modeOf(context)) {
      AdaptiveFormMode.sheet => _buildPanel(context, side: false),
      AdaptiveFormMode.side => _buildPanel(context, side: true),
      AdaptiveFormMode.dialog => _buildDialog(context),
    };
  }

  /// Panel (inferior o lateral): título arriba, contenido con scroll y
  /// botones fijos abajo, por encima del teclado.
  Widget _buildPanel(BuildContext context, {required bool side}) {
    final theme = Theme.of(context);
    // El lateral ya va dentro de un SafeArea; el inferior no protege abajo
    final bottom = side
        ? MediaQuery.viewInsetsOf(context).bottom
        : bottomSafeInset(context);
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          // Toda la altura disponible (sin pasarse de la pantalla)
          height:
              (constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height) -
              bottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  side ? 12 : 0,
                  8,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                    // El lateral no tiene píldora: botón de cerrar
                    if (side)
                      IconButton(
                        tooltip: context.l10n.cancel,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, AppSpacing.lg),
                  child: child,
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(BuildContext context) {
    final theme = Theme.of(context);
    // Tablet vertical: letra y campos más grandes para leer bien de un vistazo
    final bigger = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
        titleMedium: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
    return Theme(
      data: bigger,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(child: child),
        ),
        actions: actions,
      ),
    );
  }
}
