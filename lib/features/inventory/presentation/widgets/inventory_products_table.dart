import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../promotions/domain/promotion.dart';
import '../../domain/inventory_view.dart';
import '../../domain/product.dart';
import 'inventory_product_widgets.dart';
import 'inventory_table_cell.dart';

export 'inventory_product_widgets.dart' show InventoryProductField;

/// Tabla de inventario para pantallas anchas (tablet).
///
/// Columnas ordenables (tocando la cabecera), stock con aviso de color,
/// margen calculado y acciones al final. Las celdas se editan al tocarlas.
class InventoryProductsTable extends StatelessWidget {
  const InventoryProductsTable({
    super.key,
    required this.products,
    required this.promotions,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onEditImage,
    required this.onEditField,
    required this.onStockChange,
    required this.onEditPromotion,
    this.sort,
    this.ascending = true,
    this.onSort,
    this.onResetSort,
    this.comboNames = const {},
    this.categoryNames = const {},
    this.onEditCategory,
  });

  /// Nombre de la categoría de cada producto (por id de categoría).
  final Map<int, String> categoryNames;
  final ValueChanged<Product>? onEditCategory;

  /// Combo de cada producto (por id), solo informativo.
  final Map<int, String> comboNames;

  final List<Product> products;
  final Map<int, Promotion> promotions;
  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;
  final ValueChanged<Product> onEditImage;
  final void Function(Product product, InventoryProductField field) onEditField;
  final void Function(Product product, int amountChange) onStockChange;
  final ValueChanged<Product> onEditPromotion;

  final InventorySort? sort;
  final bool ascending;
  final ValueChanged<InventorySort>? onSort;

  /// Tocar la cabecera FOTO quita el orden y vuelve al orden por defecto.
  final VoidCallback? onResetSort;

  /// Columna de la tabla para cada criterio de orden.
  static const _sortColumns = {
    InventorySort.name: 1,
    InventorySort.units: 3,
    InventorySort.price: 4,
    InventorySort.cost: 5,
    InventorySort.margin: 6,
  };

  InventoryProductActions get _actions => InventoryProductActions(
    onEditProduct: onEditProduct,
    onDeleteProduct: onDeleteProduct,
    onEditImage: onEditImage,
    onEditField: onEditField,
    onStockChange: onStockChange,
    onEditPromotion: onEditPromotion,
    onEditCategory: onEditCategory,
  );

  DataColumn _column(
    String label, {
    InventorySort? sortBy,
    bool numeric = false,
  }) => DataColumn(
    label: Text(label.toUpperCase()),
    numeric: numeric,
    onSort: sortBy == null || onSort == null ? null : (_, _) => onSort!(sortBy),
  );

  DataRow _buildRow(BuildContext context, Product product) {
    final colors = Theme.of(context).colorScheme;
    final actions = _actions;
    final promotion = product.promotionId == null
        ? null
        : promotions[product.promotionId];
    final outOfStock = StockLevel.of(product.units) == StockLevel.out;

    return DataRow(
      // Agotado: fila ligeramente tintada para localizarlo de un vistazo
      color: outOfStock
          ? WidgetStateProperty.all(colors.error.withValues(alpha: 0.04))
          : null,
      cells: [
        DataCell(
          InventoryProductPhoto(
            product: product,
            onTap: () => onEditImage(product),
          ),
        ),
        DataCell(
          InventoryTableCell(
            text: product.name,
            onTap: () => onEditField(product, InventoryProductField.name),
            bold: true,
            maxLength: 28,
          ),
        ),
        DataCell(
          InventoryCategoryChip(
            name: categoryNames[product.categoryId],
            onTap: onEditCategory == null
                ? null
                : () => onEditCategory!(product),
          ),
        ),
        DataCell(InventoryStockStepper(product: product, actions: actions)),
        DataCell(
          InventoryTableCell(
            text: context.money(product.price),
            onTap: () => onEditField(product, InventoryProductField.price),
            bold: true,
          ),
        ),
        DataCell(
          InventoryTableCell(
            text: context.money(product.cost),
            onTap: () => onEditField(product, InventoryProductField.cost),
            textColor: colors.onSurfaceVariant,
          ),
        ),
        DataCell(
          InventoryMarginText(
            product,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InventoryPromotionChip(
                promotion: promotion,
                onTap: () => onEditPromotion(product),
              ),
              if (comboNames[product.id] != null) ...[
                const SizedBox(height: 4),
                InventoryComboTag(comboName: comboNames[product.id]!),
              ],
            ],
          ),
        ),
        DataCell(InventoryActionMenu(product: product, actions: actions)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        colors.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: colors.onSurfaceVariant,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
      sortColumnIndex: sort == null ? null : _sortColumns[sort],
      sortAscending: ascending,
      dataRowMinHeight: 64,
      dataRowMaxHeight: 68,
      horizontalMargin: 16,
      columnSpacing: 20,
      columns: [
        DataColumn(
          label: Text(context.l10n.tablePhoto.toUpperCase()),
          tooltip: sort == null ? null : context.l10n.inventorySortReset,
          onSort: sort == null || onResetSort == null
              ? null
              : (_, _) => onResetSort!(),
        ),
        _column(context.l10n.tableName, sortBy: InventorySort.name),
        _column(context.l10n.tableCategory),
        _column(context.l10n.tableUnits, sortBy: InventorySort.units),
        _column(
          context.l10n.tablePrice,
          sortBy: InventorySort.price,
          numeric: true,
        ),
        _column(
          context.l10n.tableCost,
          sortBy: InventorySort.cost,
          numeric: true,
        ),
        _column(
          context.l10n.inventoryMargin,
          sortBy: InventorySort.margin,
          numeric: true,
        ),
        _column(context.l10n.tablePromotion),
        _column(''),
      ],
      rows: products.map((p) => _buildRow(context, p)).toList(),
    );
  }
}
