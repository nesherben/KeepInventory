import 'package:flutter/material.dart';

import '../../../../core/shared_widgets/app_ui.dart';

/// Grupo de filas dentro de una sola tarjeta, separadas por líneas finas
/// (estilo ajustes). Evita una tarjeta grande por cada acción.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.borderColor});

  final List<Widget> children;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: borderColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Fila de un [SettingsGroup]: icono · título y subtítulo de una línea ·
/// control o flecha. [danger] la pinta en rojo; [loading] cambia el icono por
/// un indicador de progreso.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.loading = false,
    this.danger = false,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;

  /// Control a la derecha (interruptor, botón…). Si es nulo y la fila es
  /// pulsable, se muestra una flecha.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool loading;
  final bool danger;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = danger ? colors.error : (iconColor ?? colors.primary);
    final disabled = onTap == null && trailing == null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accent,
                      ),
                    )
                  : IconBadge(icon, color: accent, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Opacity(
                opacity: disabled ? 0.6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: danger ? colors.error : colors.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor ?? colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ] else if (onTap != null)
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de sección con el espaciado de esta pantalla.
class DataSectionLabel extends StatelessWidget {
  const DataSectionLabel(this.text, {super.key, this.first = false});

  final String text;

  /// La primera va más pegada arriba.
  final bool first;

  @override
  Widget build(BuildContext context) => SectionLabel(
    text,
    padding: EdgeInsets.fromLTRB(
      4,
      first ? 0 : AppSpacing.xl,
      4,
      AppSpacing.sm,
    ),
  );
}
