import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/product.dart';
import '../../../promotions/domain/promotion.dart';
import 'inventory_table_cell.dart';

enum InventoryProductField { name, units, price, cost }

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
  });

  final List<Product> products;
  final Map<int, Promotion> promotions;
  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;
  final ValueChanged<Product> onEditImage;
  final void Function(Product product, InventoryProductField field) onEditField;
  final void Function(Product product, int amountChange) onStockChange;
  final ValueChanged<Product> onEditPromotion;

  Widget _buildActionMenu(BuildContext context, Product product) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
      onSelected: (value) {
        if (value == 'edit') onEditProduct(product);
        if (value == 'delete') onDeleteProduct(product);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(context.l10n.editAll),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: colors.error, size: 20),
              const SizedBox(width: 8),
              Text(context.l10n.delete),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductPhoto(BuildContext context, Product product) {
    final colors = Theme.of(context).colorScheme;
    Widget image;
    if (product.imageBytes != null && product.imageBytes!.isNotEmpty) {
      image = Image.memory(
        product.imageBytes!,
        fit: BoxFit.cover,
        width: 42,
        height: 42,
      );
    } else if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      image = Image.file(
        File(product.imagePath!),
        fit: BoxFit.cover,
        width: 42,
        height: 42,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported_outlined,
          color: colors.onSurfaceVariant,
          size: 30,
        ),
      );
    } else {
      image = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.add_a_photo,
          color: colors.onSurfaceVariant,
          size: 20,
        ),
      );
    }

    return InkWell(
      onTap: () => onEditImage(product),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(6), child: image),
      ),
    );
  }

  Widget _buildStockControls(BuildContext context, Product product) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            color: colors.error,
            size: 22,
          ),
          onPressed: product.units > 0
              ? () => onStockChange(product, -1)
              : null,
        ),
        InventoryTableCell(
          text: product.units.toString(),
          onTap: () => onEditField(product, InventoryProductField.units),
          bold: true,
        ),
        IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: colors.tertiary,
            size: 22,
          ),
          onPressed: () => onStockChange(product, 1),
        ),
      ],
    );
  }

  DataRow _buildProductRow(BuildContext context, Product product) {
    final hasPromotion =
        product.promotionId != null &&
        promotions.containsKey(product.promotionId);
    final promotionName = hasPromotion
        ? promotions[product.promotionId]!.name
        : context.l10n.noPromotion;

    return DataRow(
      cells: [
        DataCell(_buildActionMenu(context, product)),
        DataCell(_buildProductPhoto(context, product)),
        DataCell(
          InventoryTableCell(
            text: product.name,
            onTap: () => onEditField(product, InventoryProductField.name),
            maxLength: 20,
          ),
        ),
        DataCell(_buildStockControls(context, product)),
        DataCell(
          InventoryTableCell(
            text: '${product.price.toStringAsFixed(2)} €',
            onTap: () => onEditField(product, InventoryProductField.price),
          ),
        ),
        DataCell(
          InventoryTableCell(
            text: '${product.cost.toStringAsFixed(2)} €',
            onTap: () => onEditField(product, InventoryProductField.cost),
          ),
        ),
        DataCell(
          InventoryTableCell(
            text: promotionName,
            onTap: () => onEditPromotion(product),
            textColor: hasPromotion
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            bold: hasPromotion,
            maxLength: 18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        colors.primary.withValues(alpha: 0.08),
      ),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: colors.primary,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
      dataRowMinHeight: 60,
      dataRowMaxHeight: 65,
      horizontalMargin: 16,
      columnSpacing: 24,
      columns: [
        DataColumn(label: Text(context.l10n.tableActions)),
        DataColumn(label: Text(context.l10n.tablePhoto)),
        DataColumn(label: Text(context.l10n.tableName)),
        DataColumn(label: Text(context.l10n.tableUnits)),
        DataColumn(label: Text(context.l10n.tablePrice)),
        DataColumn(label: Text(context.l10n.tableCost)),
        DataColumn(label: Text(context.l10n.tablePromotion)),
      ],
      rows: products
          .map((product) => _buildProductRow(context, product))
          .toList(),
    );
  }
}
