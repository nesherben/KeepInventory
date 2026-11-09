import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../domain/inventory_view.dart';
import '../../domain/product.dart';
import '../../domain/product_category.dart';

/// Hoja inferior con buscador para elegir un producto (sustituye a los
/// desplegables, incómodos con muchos productos). Ordena por nombre y
/// devuelve el producto tocado.
///
/// [disabledReason] devuelve el motivo si un producto no se puede elegir.
Future<Product?> showProductPicker(
  BuildContext context, {
  required List<Product> products,
  int? selectedId,
  String? Function(Product product)? disabledReason,
}) async {
  final pick = await showProductOrCategoryPicker(
    context,
    products: products,
    selectedId: selectedId,
    disabledReason: disabledReason,
  );
  return pick?.product;
}

/// Lo elegido en [showProductOrCategoryPicker]: un producto o una categoría.
class ProductOrCategory {
  const ProductOrCategory.product(Product this.product) : category = null;
  const ProductOrCategory.category(ProductCategory this.category)
    : product = null;

  final Product? product;
  final ProductCategory? category;
}

/// Como [showProductPicker] pero, si hay [categories], arriba aparecen las
/// categorías ("cualquier producto de…"), p. ej. para huecos de combo.
Future<ProductOrCategory?> showProductOrCategoryPicker(
  BuildContext context, {
  required List<Product> products,
  List<ProductCategory> categories = const [],
  int? selectedId,
  int? selectedCategoryId,
  String? Function(Product product)? disabledReason,

  /// Se ofrecen categorías (p. ej. huecos de combo): si no hay ninguna, se
  /// explica cómo crearlas.
  bool offerCategories = false,
}) {
  final sorted = [...products]
    ..sort((a, b) => InventoryView.compareNames(a.name, b.name));
  var query = '';

  // Nº de productos de cada categoría (las vacías también se ofrecen, con
  // su aviso: el combo se activará cuando tengan productos)
  final counts = <int, int>{};
  for (final p in products) {
    if (p.categoryId != null) {
      counts[p.categoryId!] = (counts[p.categoryId!] ?? 0) + 1;
    }
  }
  final usableCategories = [...categories];

  return showModalBottomSheet<ProductOrCategory>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final q = query.trim().toLowerCase();
        final visible = sorted
            .where((p) => p.name.toLowerCase().contains(q))
            .toList();
        final visibleCategories = usableCategories
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();
        return Padding(
          // Que el teclado no tape la lista
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.productPickerTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: sorted.length > 8,
                    onChanged: (v) => setSheet(() => query = v),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchProduct,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (offerCategories && categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sell_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              context.l10n.comboSlotNoCategories,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty && visibleCategories.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: context.l10n.productsNotFound,
                        )
                      : ListView.builder(
                          itemCount:
                              visible.length +
                              (visibleCategories.isEmpty
                                  ? 0
                                  : visibleCategories.length + 2),
                          itemBuilder: (context, index) {
                            // Primero las categorías (con cabeceras)
                            if (visibleCategories.isNotEmpty) {
                              if (index == 0) {
                                return SectionLabel(
                                  context.l10n.comboSlotCategories,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    4,
                                  ),
                                );
                              }
                              if (index <= visibleCategories.length) {
                                final c = visibleCategories[index - 1];
                                final selected = c.id == selectedCategoryId;
                                return ListTile(
                                  leading: const Icon(Icons.sell_outlined),
                                  selected: selected,
                                  title: Text(
                                    context.l10n.comboSlotAnyOf(c.name),
                                  ),
                                  subtitle: Text(
                                    (counts[c.id] ?? 0) == 0
                                        ? context.l10n.comboSlotEmptyCategory
                                        : context.l10n.unitCount(
                                            '${counts[c.id]}',
                                          ),
                                  ),
                                  trailing: selected
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () => Navigator.pop(
                                    context,
                                    ProductOrCategory.category(c),
                                  ),
                                );
                              }
                              if (index == visibleCategories.length + 1) {
                                return SectionLabel(
                                  context.l10n.comboSlotProducts,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    4,
                                  ),
                                );
                              }
                              index -= visibleCategories.length + 2;
                            }
                            final product = visible[index];
                            final reason = disabledReason?.call(product);
                            final selected = product.id == selectedId;
                            return ListTile(
                              enabled: reason == null,
                              selected: selected,
                              minVerticalPadding: 10,
                              onTap: () => Navigator.pop(
                                context,
                                ProductOrCategory.product(product),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                reason ??
                                    '${context.money(product.price)} · '
                                        '${context.l10n.unitCount(product.units.toString())}',
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
