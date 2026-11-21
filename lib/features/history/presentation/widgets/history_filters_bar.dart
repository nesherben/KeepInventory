import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../domain/change_entry.dart';
import '../../domain/change_log_filter.dart';
import '../history_texts.dart';

/// Intervalos de fecha del filtro.
enum HistoryDateRange { any, today, week, month }

/// Búsqueda y filtros del historial: texto, tipo de elemento, acción y fecha.
/// No guarda estado: avisa con el filtro nuevo y la pantalla lo aplica.
class HistoryFiltersBar extends StatelessWidget {
  const HistoryFiltersBar({
    super.key,
    required this.controller,
    required this.filter,
    required this.dateRange,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
  });

  final TextEditingController controller;
  final ChangeLogFilter filter;
  final HistoryDateRange dateRange;
  final ValueChanged<ChangeLogFilter> onFilterChanged;
  final ValueChanged<HistoryDateRange> onDateRangeChanged;

  String _rangeLabel(BuildContext context, HistoryDateRange range) =>
      switch (range) {
        HistoryDateRange.any => context.l10n.historyDateAny,
        HistoryDateRange.today => context.l10n.historyDateToday,
        HistoryDateRange.week => context.l10n.historyDateWeek,
        HistoryDateRange.month => context.l10n.historyDateMonth,
      };

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.sm),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (value) =>
                      onFilterChanged(filter.copyWith(query: value)),
                  decoration: InputDecoration(
                    hintText: context.l10n.changesSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: filter.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              controller.clear();
                              onFilterChanged(filter.copyWith(query: ''));
                            },
                          )
                        : null,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton<HistoryDateRange>(
                tooltip: _rangeLabel(context, dateRange),
                initialValue: dateRange,
                onSelected: onDateRangeChanged,
                icon: Icon(
                  Icons.event_outlined,
                  color: dateRange == HistoryDateRange.any
                      ? colors.onSurfaceVariant
                      : colors.primary,
                ),
                itemBuilder: (context) => [
                  for (final range in HistoryDateRange.values)
                    PopupMenuItem(
                      value: range,
                      child: Text(_rangeLabel(context, range)),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Tipo de elemento
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _chip(
                label: context.l10n.historyEntityAll,
                selected: filter.entity == null,
                onSelected: () =>
                    onFilterChanged(filter.copyWith(clearEntity: true)),
              ),
              for (final entity in ChangeEntity.values)
                _chip(
                  label: context.historyKindPlural(entity),
                  selected: filter.entity == entity,
                  onSelected: () =>
                      onFilterChanged(filter.copyWith(entity: entity)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Acción
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _chip(
                label: context.l10n.historyActionAll,
                selected: filter.action == null,
                onSelected: () =>
                    onFilterChanged(filter.copyWith(clearAction: true)),
              ),
              for (final action in ChangeAction.values)
                _chip(
                  label: context.historyAction(action),
                  selected: filter.action == action,
                  onSelected: () =>
                      onFilterChanged(filter.copyWith(action: action)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
