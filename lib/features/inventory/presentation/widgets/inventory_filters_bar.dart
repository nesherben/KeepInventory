import 'package:flutter/material.dart';
import 'package:keepinventory/core/shared_widgets/app_ui.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/inventory_view.dart';

class InventoryFiltersBar extends StatelessWidget {
  const InventoryFiltersBar({
    super.key,
    required this.summary,
    required this.filter,
    required this.onFilterChanged,
    required this.categoryNames,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.onResetSort,
    required this.isNarrow,
  });

  final InventorySummary summary;
  final InventoryFilter filter;
  final ValueChanged<InventoryFilter> onFilterChanged;
  final Map<int, String> categoryNames;
  final int? categoryFilter;
  final ValueChanged<int?> onCategoryChanged;
  final InventorySort? sort;
  final bool ascending;
  final ValueChanged<InventorySort> onSort;
  final VoidCallback onResetSort;
  final bool isNarrow;

  String _sortLabel(BuildContext context, InventorySort sort) => switch (sort) {
    InventorySort.name => context.l10n.inventorySortName,
    InventorySort.units => context.l10n.inventorySortUnits,
    InventorySort.price => context.l10n.inventorySortPrice,
    InventorySort.cost => context.l10n.inventorySortCost,
    InventorySort.margin => context.l10n.inventoryMargin,
  };

  Widget _buildCategoryFilter(BuildContext context) {
    final selected = categoryFilter;
    final names = categoryNames.entries.toList()
      ..sort((a, b) => InventoryView.compareNames(a.value, b.value));

    return PopupMenuButton<int>(
      tooltip: context.l10n.productCategory,
      onSelected: (id) => onCategoryChanged(id == -1 ? null : id),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: -1,
          checked: selected == null,
          child: Text(context.l10n.categoryAll),
        ),
        const PopupMenuDivider(),
        for (final entry in names)
          CheckedPopupMenuItem(
            value: entry.key,
            checked: selected == entry.key,
            child: Text(entry.value),
          ),
      ],
      child: IgnorePointer(
        child: FilterChip(
          avatar: const Icon(Icons.sell_outlined, size: 16),
          label: Text(
            selected == null
                ? context.l10n.productCategory
                : categoryNames[selected]!,
          ),
          selected: selected != null,
          showCheckmark: false,
          onSelected: (_) {},
        ),
      ),
    );
  }

  Widget _buildSortButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = sort;
    final arrow = ascending ? Icons.arrow_upward : Icons.arrow_downward;
    const defaultChoice = -1;

    PopupMenuItem<int> option(int value, String label, bool selected) =>
        PopupMenuItem<int>(
          value: value,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: selected
                    ? Icon(
                        value == defaultChoice ? Icons.check : arrow,
                        size: 18,
                        color: colors.primary,
                      )
                    : null,
              ),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? colors.primary : null,
                ),
              ),
            ],
          ),
        );

    return PopupMenuButton<int>(
      tooltip: context.l10n.inventorySortTitle,
      onSelected: (value) => value == defaultChoice
          ? onResetSort()
          : onSort(InventorySort.values[value]),
      itemBuilder: (context) => [
        option(
          defaultChoice,
          context.l10n.inventorySortDefault,
          active == null,
        ),
        const PopupMenuDivider(),
        for (final criterion in InventorySort.values)
          option(
            criterion.index,
            _sortLabel(context, criterion),
            active == criterion,
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 18,
              color: active == null ? colors.onSurfaceVariant : colors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              active == null
                  ? context.l10n.inventorySortTitle
                  : _sortLabel(context, active),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active == null
                    ? colors.onSurfaceVariant
                    : colors.primary,
              ),
            ),
            if (active != null) ...[
              const SizedBox(width: 2),
              Icon(arrow, size: 14, color: colors.primary),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget chip(InventoryFilter value, String label, {int? count}) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(count == null ? label : '$label ($count)'),
          selected: filter == value,
          showCheckmark: false,
          onSelected: (_) => onFilterChanged(value),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              chip(InventoryFilter.all, context.l10n.inventoryFilterAll),
              chip(
                InventoryFilter.lowStock,
                context.l10n.inventoryFilterLow,
                count: summary.lowStock,
              ),
              chip(
                InventoryFilter.outOfStock,
                context.l10n.inventoryFilterOut,
                count: summary.outOfStock,
              ),
              chip(
                InventoryFilter.withPromotion,
                context.l10n.inventoryFilterPromo,
              ),
              if (categoryNames.isNotEmpty) _buildCategoryFilter(context),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, isNarrow ? 4 : 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.inventorySummary(
                    summary.products,
                    summary.units,
                    summary.outOfStock,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (isNarrow) _buildSortButton(context),
            ],
          ),
        ),
      ],
    );
  }
}
