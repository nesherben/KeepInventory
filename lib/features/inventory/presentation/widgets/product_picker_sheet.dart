import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../domain/inventory_view.dart';
import '../../domain/product.dart';

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
}) {
  final sorted = [...products]
    ..sort((a, b) => InventoryView.compareNames(a.name, b.name));
  var query = '';

  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final q = query.trim().toLowerCase();
        final visible = sorted
            .where((p) => p.name.toLowerCase().contains(q))
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
                Expanded(
                  child: visible.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: context.l10n.productsNotFound,
                        )
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final product = visible[index];
                            final reason = disabledReason?.call(product);
                            final selected = product.id == selectedId;
                            return ListTile(
                              enabled: reason == null,
                              selected: selected,
                              minVerticalPadding: 10,
                              onTap: () => Navigator.pop(context, product),
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
