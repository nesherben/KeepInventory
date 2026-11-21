import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_drawer.dart';
import '../../../core/shared_widgets/app_ui.dart';
import '../data/datasources/history_local_datasource.dart';
import '../data/repositories/history_repository_impl.dart';
import '../domain/change_day_group.dart';
import '../domain/change_entry.dart';
import '../domain/change_log_filter.dart';
import '../domain/repositories/history_repository.dart';
import 'history_texts.dart';
import 'widgets/history_entry_sheet.dart';
import 'widgets/history_entry_tile.dart';
import 'widgets/history_filters_bar.dart';

/// Historial de cambios de configuración: lista cronológica (lo más nuevo
/// arriba) agrupada por día, con búsqueda, filtros y detalle de cada entrada.
class HistoryChangesScreen extends StatefulWidget {
  const HistoryChangesScreen({super.key});

  @override
  State<HistoryChangesScreen> createState() => _HistoryChangesScreenState();
}

class _HistoryChangesScreenState extends State<HistoryChangesScreen> {
  final HistoryRepository _repository = HistoryRepositoryImpl(
    HistoryLocalDatasource(),
  );
  final _searchController = TextEditingController();

  List<ChangeEntry> _entries = [];
  ChangeLogFilter _filter = const ChangeLogFilter();
  HistoryDateRange _dateRange = HistoryDateRange.any;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _repository.getEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  void _setDateRange(HistoryDateRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final since = switch (range) {
      HistoryDateRange.any => null,
      HistoryDateRange.today => today,
      HistoryDateRange.week => today.subtract(const Duration(days: 6)),
      HistoryDateRange.month => today.subtract(const Duration(days: 29)),
    };
    setState(() {
      _dateRange = range;
      _filter = since == null
          ? _filter.copyWith(clearSince: true)
          : _filter.copyWith(since: since);
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _filter = const ChangeLogFilter();
      _dateRange = HistoryDateRange.any;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter.apply(_entries);
    final groups = groupChangesByDay(visible);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.historyTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? EmptyState(
              icon: Icons.history,
              title: context.l10n.historyEmptyTitle,
              message: context.l10n.historyEmptyMessage,
            )
          : Column(
              children: [
                HistoryFiltersBar(
                  controller: _searchController,
                  filter: _filter,
                  dateRange: _dateRange,
                  onFilterChanged: (filter) => setState(() => _filter = filter),
                  onDateRangeChanged: _setDateRange,
                ),
                Expanded(
                  child: groups.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: context.l10n.changesNoResults,
                          action: TextButton(
                            onPressed: _clearFilters,
                            child: Text(context.l10n.changesClearFilters),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.xl +
                                MediaQuery.viewPaddingOf(context).bottom,
                          ),
                          children: [
                            for (final group in groups) ...[
                              SectionLabel(
                                context.historyDayLabel(group.day),
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                  bottom: AppSpacing.sm,
                                ),
                              ),
                              for (final entry in group.entries)
                                HistoryEntryTile(
                                  entry: entry,
                                  onTap: () => showHistoryEntrySheet(
                                    context,
                                    entry: entry,
                                    all: _entries,
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
