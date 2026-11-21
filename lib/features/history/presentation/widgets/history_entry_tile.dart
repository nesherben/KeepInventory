import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/change_entry.dart';
import '../history_texts.dart';

/// Una entrada de la lista: icono con el color de la acción, nombre, qué se
/// hizo y, en las ediciones, el primer cambio con su antes y después.
class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({super.key, required this.entry, required this.onTap});

  final ChangeEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = historyActionColor(entry.action, undone: entry.undone);
    final fields = entry.action == ChangeAction.update
        ? entry.changedFields
        : const <String>[];

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(historyEntityIcon(entry.entity), color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.entityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    decoration: entry.undone
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      context.historyAction(entry.action),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      ' · ${context.historyKind(entry.entity)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (entry.undone) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        context.l10n.historyUndone,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
                if (fields.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.historyChangeSummary(entry, fields.first),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.onSurface),
                  ),
                  if (fields.length > 1)
                    Text(
                      context.l10n.historyMoreChanges(fields.length - 1),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.historyTime(entry.createdAt),
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
