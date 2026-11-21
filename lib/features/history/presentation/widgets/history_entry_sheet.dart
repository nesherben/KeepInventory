import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/adaptive_form.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/change_day_group.dart';
import '../../domain/change_entry.dart';
import '../history_texts.dart';

/// Detalle de una entrada: qué era, cuándo y cada campo con su antes y después.
Future<void> showHistoryEntrySheet(
  BuildContext context, {
  required ChangeEntry entry,
  required List<ChangeEntry> all,
}) {
  return AdaptiveForm.show<void>(
    context,
    builder: (_) => _HistoryEntrySheet(entry: entry, all: all),
  );
}

class _HistoryEntrySheet extends StatelessWidget {
  const _HistoryEntrySheet({required this.entry, required this.all});

  final ChangeEntry entry;
  final List<ChangeEntry> all;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = historyActionColor(entry.action, undone: entry.undone);
    final operation = operationOf(entry, all);
    final d = entry.createdAt;
    final when =
        '${context.historyDayLabel(DateTime(d.year, d.month, d.day))} · '
        '${context.historyTime(d)}';
    final showBefore = entry.action != ChangeAction.create;
    final showAfter = entry.action != ChangeAction.delete;

    return AdaptiveFormScaffold(
      title: entry.entityName,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.close),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(historyEntityIcon(entry.entity), color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.historyAction(entry.action)} · '
                      '${context.historyKind(entry.entity)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      when,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.undone)
                Text(
                  context.l10n.historyUndone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          if (operation.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.historyOperation(operation.length),
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (showBefore && showAfter)
            Row(
              children: [
                const Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(flex: 3, child: _Header(context.l10n.historyBefore)),
                Expanded(flex: 3, child: _Header(context.l10n.historyAfter)),
              ],
            ),
          for (final field in entry.changedFields)
            _FieldRow(
              label: context.historyField(field),
              before: showBefore
                  ? context.historyValue(field, entry.before)
                  : null,
              after: showAfter
                  ? context.historyValue(field, entry.after)
                  : null,
              dual: showBefore && showAfter,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Un campo: etiqueta y su valor (antes y después, o solo uno en creaciones
/// y borrados).
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.before,
    required this.after,
    required this.dual,
  });

  final String label;
  final String? before;
  final String? after;
  final bool dual;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget value(String? text, {bool strong = false}) => Text(
      text ?? '',
      style: TextStyle(
        fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
        color: strong ? colors.onSurface : colors.onSurfaceVariant,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          if (dual) ...[
            Expanded(flex: 3, child: value(before)),
            Expanded(flex: 3, child: value(after, strong: true)),
          ] else
            Expanded(flex: 6, child: value(before ?? after, strong: true)),
        ],
      ),
    );
  }
}
