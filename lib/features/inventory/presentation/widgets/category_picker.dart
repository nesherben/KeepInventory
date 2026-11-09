import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_alerts.dart';
import '../../../../core/shared_widgets/name_picker_sheet.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/product_category.dart';

/// Resultado de elegir categoría: [category] null = "Sin categoría".
class CategoryPick {
  const CategoryPick(this.category);
  final ProductCategory? category;
}

/// Panel para elegir, crear o borrar categorías (mismo panel que las ferias).
/// Devuelve null si se cerró sin elegir.
Future<CategoryPick?> pickCategory(
  BuildContext context, {
  int? currentId,
}) async {
  final repository = CategoryRepositoryImpl(CategoryLocalDatasource());
  final categories = await repository.getCategories();
  if (!context.mounted) return null;
  final l10n = context.l10n;
  final byName = {for (final c in categories) c.name: c};
  final current = categories.where((c) => c.id == currentId).firstOrNull;

  final chosen = await showNamePickerSheet(
    context,
    title: l10n.categoryPickTitle,
    searchHint: l10n.categorySearchOrCreate,
    names: [for (final c in categories) c.name],
    createLabel: l10n.categoryCreate,
    current: current?.name,
    removeLabel: l10n.categoryRemove,
    deleteTooltip: l10n.categoryDeleteTitle,
    icon: Icons.sell_outlined,
    onDelete: (sheetContext, name) async {
      final category = byName[name];
      if (category == null) return false;
      final count = await repository.countProducts(category.id);
      if (!sheetContext.mounted) return false;
      final ok = await confirmDeleteDialog(
        sheetContext,
        title: l10n.categoryDeleteTitle,
        message: count > 0
            ? l10n.categoryDeleteConfirmUsed(count, name)
            : l10n.categoryDeleteConfirmEmpty(name),
        cancelLabel: l10n.cancel,
        deleteLabel: l10n.delete,
      );
      if (!ok) return false;
      await repository.delete(category.id);
      if (context.mounted) AppAlerts.showWarning(context, l10n.categoryDeleted);
      return true;
    },
  );

  if (chosen == null) return null;
  if (chosen.isEmpty) return const CategoryPick(null);
  return CategoryPick(byName[chosen] ?? await repository.getOrCreate(chosen));
}

/// Campo de formulario (solo lectura) que abre [pickCategory].
class CategoryField extends StatelessWidget {
  const CategoryField({
    super.key,
    required this.categoryName,
    required this.onTap,
  });

  final String? categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.l10n.productCategory,
          prefixIcon: const Icon(Icons.sell_outlined, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          categoryName ?? context.l10n.categoryNone,
          style: TextStyle(
            color: categoryName == null ? colors.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
