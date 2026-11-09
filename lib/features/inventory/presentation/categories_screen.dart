import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/shared_widgets/app_alerts.dart';
import '../../../core/shared_widgets/app_ui.dart';
import '../../../core/shared_widgets/name_picker_sheet.dart';
import '../data/datasources/category_local_datasource.dart';
import '../data/datasources/product_local_datasource.dart';
import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/inventory_view.dart';
import '../domain/product_category.dart';

/// Gestión de categorías: ver cuántos productos tiene cada una, crear,
/// renombrar, borrar y meter/sacar varios productos de golpe.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _repository = CategoryRepositoryImpl(CategoryLocalDatasource());
  final _productRepository = ProductRepositoryImpl(ProductLocalDatasource());
  List<ProductCategory> _categories = [];
  Map<int, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await _repository.getCategories();
    final counts = await _repository.countAll();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _counts = counts;
      _loading = false;
    });
  }

  /// Pide un nombre (nuevo o renombrar). Null si se cancela.
  Future<String?> _askName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial)
      ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.categoryNameLabel,
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    final clean = name?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  Future<void> _create() async {
    final name = await _askName(context.l10n.categoryNew);
    if (name == null) return;
    await _repository.getOrCreate(name);
    _load();
  }

  Future<void> _rename(ProductCategory category) async {
    final name = await _askName(
      context.l10n.categoryRename,
      initial: category.name,
    );
    if (name == null || name == category.name) return;
    final ok = await _repository.rename(category.id, name);
    if (!mounted) return;
    if (!ok) {
      AppAlerts.showError(context, context.l10n.categoryNameTaken);
      return;
    }
    AppAlerts.showSuccess(context, context.l10n.categoryUpdated);
    _load();
  }

  Future<void> _delete(ProductCategory category) async {
    final l10n = context.l10n;
    final count = _counts[category.id] ?? 0;
    final ok = await confirmDeleteDialog(
      context,
      title: l10n.categoryDeleteTitle,
      message: count > 0
          ? l10n.categoryDeleteConfirmUsed(count, category.name)
          : l10n.categoryDeleteConfirmEmpty(category.name),
      cancelLabel: l10n.cancel,
      deleteLabel: l10n.delete,
    );
    if (!ok) return;
    await _repository.delete(category.id);
    if (!mounted) return;
    AppAlerts.showWarning(context, l10n.categoryDeleted);
    _load();
  }

  /// Lista de productos con casillas para meter/sacar varios de golpe.
  Future<void> _editProducts(ProductCategory category) async {
    final products = await _productRepository.getProducts();
    if (!mounted) return;
    products.sort((a, b) => InventoryView.compareNames(a.name, b.name));
    final names = {for (final c in _categories) c.id: c.name};
    final initial = {
      for (final p in products)
        if (p.categoryId == category.id) p.id!,
    };
    final selected = {...initial};
    var query = '';

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final q = query.trim().toLowerCase();
          final visible = products
              .where((p) => p.name.toLowerCase().contains(q))
              .toList();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.8,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sheetContext.l10n.categoryProductsTitle(
                              category.name,
                            ),
                            style: Theme.of(sheetContext).textTheme.titleMedium,
                          ),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: Text(sheetContext.l10n.save),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (v) => setSheet(() => query = v),
                      decoration: InputDecoration(
                        hintText: sheetContext.l10n.searchProduct,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final p = visible[index];
                        final other =
                            p.categoryId != null && p.categoryId != category.id
                            ? names[p.categoryId]
                            : null;
                        return CheckboxListTile(
                          value: selected.contains(p.id),
                          onChanged: (v) => setSheet(
                            () => v == true
                                ? selected.add(p.id!)
                                : selected.remove(p.id!),
                          ),
                          title: Text(p.name),
                          // Marcarlo lo cambia de categoría
                          subtitle: other == null
                              ? null
                              : Text(context.l10n.categoryInOther(other)),
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
    if (save != true) return;
    await _repository.setProducts(
      category.id,
      add: selected.difference(initial),
      remove: initial.difference(selected),
    );
    if (!mounted) return;
    AppAlerts.showSuccess(context, context.l10n.categoryUpdated);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.categoriesTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? EmptyState(
              icon: Icons.sell_outlined,
              title: context.l10n.categoriesEmpty,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                  onTap: () => _editProducts(category),
                  child: Row(
                    children: [
                      const IconBadge(Icons.sell_outlined),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              context.l10n.categoryProductsCount(
                                _counts[category.id] ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.categoryRename,
                        icon: Icon(
                          Icons.edit_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                        onPressed: () => _rename(category),
                      ),
                      IconButton(
                        tooltip: context.l10n.categoryDeleteTitle,
                        icon: Icon(Icons.delete_outline, color: colors.error),
                        onPressed: () => _delete(category),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.categoryNew),
      ),
    );
  }
}
