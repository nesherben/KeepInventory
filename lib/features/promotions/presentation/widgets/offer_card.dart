import 'package:flutter/material.dart';

import '../../../../core/shared_widgets/app_ui.dart';

/// Acción del menú ⋮ de una tarjeta de oferta.
class OfferAction {
  const OfferAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

/// Tarjeta de promoción o combo, con el mismo patrón que el inventario:
/// tocar la tarjeta = editar; ⋮ = resto de acciones.
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.icon,
    required this.title,
    required this.lines,
    required this.onTap,
    required this.actions,
    this.iconColor,
    this.highlight,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;

  /// Líneas de detalle bajo el título (regla, productos, ahorro…).
  final List<String> lines;

  /// Línea opcional destacada (p. ej. el ahorro).
  final String? highlight;
  final VoidCallback onTap;
  final List<OfferAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (highlight != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      highlight!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
            onSelected: (i) => actions[i].onTap(),
            itemBuilder: (context) => [
              for (var i = 0; i < actions.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Row(
                    children: [
                      Icon(
                        actions[i].icon,
                        size: 20,
                        color: actions[i].destructive
                            ? colors.error
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(actions[i].label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
