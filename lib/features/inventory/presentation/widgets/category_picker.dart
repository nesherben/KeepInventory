import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/name_picker_sheet.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/product_category.dart';

/// Resultado de elegir categoría: [category] null = "Sin categoría".
class CategoryPick {
  const CategoryPick(this.category);
  final ProductCategory? category;
}

/// Panel para elegir o crear categorías (mismo panel que las ferias). Para
/// renombrar o borrar: Inventario → Categorías. Null si se cerró sin elegir.
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
    icon: Icons.sell_outlined,
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
    this.label,
  });

  final String? categoryName;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label ?? context.l10n.productCategory,
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
