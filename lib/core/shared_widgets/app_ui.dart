import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Medidas del sistema visual de la app. Úsalas en vez de números sueltos
/// para que todas las pantallas compartan el mismo estilo.
abstract final class AppRadius {
  /// Chips, swatches, barras pequeñas.
  static const double sm = 8;

  /// Botones, campos de texto, tiles internos.
  static const double md = 12;

  /// Tarjetas.
  static const double lg = 16;

  /// Diálogos, hojas inferiores, tarjeta principal.
  static const double xl = 20;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Margen exterior de pantalla según el ancho.
  static double page(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 24 : 16;
}

/// Tarjeta plana con borde fino (sin sombra). Opcionalmente pulsable y con
/// estado "seleccionado" (fondo y borde del color primario).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.borderColor,
    this.color,
    this.radius = AppRadius.lg,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final Color? borderColor;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: selected
            ? colors.primary.withValues(alpha: 0.4)
            : borderColor ?? theme.dividerColor,
      ),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: selected
            ? Color.alphaBlend(
                colors.primary.withValues(alpha: 0.08),
                theme.cardColor,
              )
            : color ?? theme.cardColor,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null && onLongPress == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

/// Título pequeño en mayúsculas para separar secciones.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: trailing == null
          ? label
          : Row(
              children: [
                Expanded(child: label),
                trailing!,
              ],
            ),
    );
  }
}

/// Icono dentro de un cuadrado redondeado tintado.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color, this.size = 20});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.all(size * 0.4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md - 2),
      ),
      child: Icon(icon, color: c, size: size),
    );
  }
}

/// Cifra clave: etiqueta pequeña + valor grande (texto siempre en tinta;
/// el color de identidad va solo en el icono).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
    this.valueSize = 18,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconBadge(icon!, color: iconColor, size: 18),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Control compacto "− valor +" para ajustar unidades rápidamente.
/// Rojo cuando [isEmpty] (sin unidades), naranja cuando [isLow].
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.label,
    required this.onIncrement,
    this.onDecrement,
    this.onTapLabel,
    this.isEmpty = false,
    this.isLow = false,
  });

  final String label;
  final VoidCallback onIncrement;

  /// Nulo = botón "−" deshabilitado.
  final VoidCallback? onDecrement;

  /// Tocar el número (p. ej. para escribir la cantidad exacta).
  final VoidCallback? onTapLabel;
  final bool isEmpty;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = isEmpty
        ? colors.error
        : isLow
        ? AppColors.warning
        : colors.primary;

    Widget button(IconData icon, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? colors.onSurfaceVariant.withValues(alpha: 0.4)
              : accent,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, onDecrement),
          InkWell(
            onTap: onTapLabel,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isEmpty ? colors.error : colors.onSurface,
                ),
              ),
            ),
          ),
          button(Icons.add, onIncrement),
        ],
      ),
    );
  }
}

/// Estado vacío: icono grande, título y mensaje opcional con acción.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
