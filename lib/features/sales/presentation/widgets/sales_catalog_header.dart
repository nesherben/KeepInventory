import 'package:flutter/material.dart';
import 'package:keepinventory/core/shared_widgets/app_ui.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../inventory/domain/product_category.dart';

class SalesCatalogHeader extends StatelessWidget {
  const SalesCatalogHeader({
    super.key,
    required this.isProductTab,
    required this.productSearchController,
    required this.packSearchController,
    required this.productSearchQuery,
    required this.packSearchQuery,
    required this.categories,
    required this.categoryFilter,
    required this.onProductSearchChanged,
    required this.onPackSearchChanged,
    required this.onCategoryChanged,
  });

  final bool isProductTab;
  final TextEditingController productSearchController;
  final TextEditingController packSearchController;
  final String productSearchQuery;
  final String packSearchQuery;
  final List<ProductCategory> categories;
  final int? categoryFilter;
  final ValueChanged<String> onProductSearchChanged;
  final ValueChanged<String> onPackSearchChanged;
  final ValueChanged<int?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final controller = isProductTab
        ? productSearchController
        : packSearchController;
    final query = isProductTab ? productSearchQuery : packSearchQuery;
    final onSearchChanged = isProductTab
        ? onProductSearchChanged
        : onPackSearchChanged;

    final searchField = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: isProductTab
              ? context.l10n.searchProducts
              : context.l10n.searchPacksOrComponents,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                ),
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );

    if (!isProductTab || categories.isEmpty) return searchField;

    Widget chip(int? id, String label) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: categoryFilter == id,
        showCheckmark: false,
        onSelected: (_) => onCategoryChanged(id),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        searchField,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
          child: Row(
            children: [
              chip(null, context.l10n.categoryAll),
              for (final category in categories)
                chip(category.id, category.name),
            ],
          ),
        ),
      ],
    );
  }
}
