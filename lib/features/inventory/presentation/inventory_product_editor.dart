import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keepinventory/core/services/image_compression_service.dart';
import 'package:keepinventory/core/shared_widgets/adaptive_form.dart';
import 'package:keepinventory/core/shared_widgets/app_alerts.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../data/repositories/product_repository_impl.dart';
import '../domain/product.dart';
import '../../promotions/domain/promotion.dart';
import 'widgets/category_picker.dart';
import 'widgets/inventory_product_widgets.dart';
import 'widgets/product_form_dialog.dart';

class InventoryProductEditor {
  InventoryProductEditor({
    required this.repository,
    required this.promotions,
    required this.categories,
    required this.reloadProducts,
    required this.discardPendingStock,
  });

  final ProductRepositoryImpl repository;
  final Map<int, Promotion> Function() promotions;
  final Map<int, String> Function() categories;
  final VoidCallback reloadProducts;
  final ValueChanged<int> discardPendingStock;

  final ImagePicker _picker = ImagePicker();

  Future<void> processAndSaveNewImage(
    BuildContext context,
    Product product,
    ImageSource source,
  ) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final compressedBytes = await ImageCompressionService.compressFile(
      File(pickedFile.path),
    );
    await repository.updateFields(product.id!, imageBytes: compressedBytes);
    reloadProducts();

    if (context.mounted) {
      AppAlerts.showSuccess(context, context.l10n.photoUpdated);
    }
  }

  Future<void> deleteProduct(BuildContext context, int id) async {
    discardPendingStock(id);
    await repository.deleteProduct(id);
    reloadProducts();

    if (context.mounted) {
      AppAlerts.showWarning(context, context.l10n.productDeleted);
    }
  }

  void showDeleteConfirmation(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.deleteProductTitle),
        content: Text(dialogContext.l10n.deleteProductConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              deleteProduct(context, id);
            },
            child: Text(dialogContext.l10n.delete),
          ),
        ],
      ),
    );
  }

  void showEditSingleFieldDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
    required Future<void> Function(String) onSave,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    final controller = TextEditingController(text: initialValue)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: initialValue.length,
      );

    var saving = false;
    Future<void> save() async {
      if (saving) return;
      saving = true;
      try {
        await onSave(controller.text);
      } finally {
        saving = false;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.editFieldTitle(title)),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: dialogContext.l10n.newValue,
            suffixText: suffixText,
          ),
          autofocus: true,
          onSubmitted: (_) => save(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.cancel),
          ),
          ElevatedButton(onPressed: save, child: Text(dialogContext.l10n.save)),
        ],
      ),
    );
  }

  void showPromotionSelectDialog(BuildContext context, Product product) {
    int? selectedPromotionId = product.promotionId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogContext.l10n.selectPromotion),
          content: DropdownButtonFormField<int?>(
            initialValue: selectedPromotionId,
            decoration: InputDecoration(
              labelText: dialogContext.l10n.appliedPromotion,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(dialogContext.l10n.noPromotion),
              ),
              ...promotions().values.map(
                (promotion) => DropdownMenuItem(
                  value: promotion.id,
                  child: Text(promotion.name),
                ),
              ),
            ],
            onChanged: (value) {
              setDialogState(() => selectedPromotionId = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                await repository.updateFields(
                  product.id!,
                  promotionId: selectedPromotionId,
                  clearPromotion: selectedPromotionId == null,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                reloadProducts();
                AppAlerts.showSuccess(
                  dialogContext,
                  dialogContext.l10n.promotionUpdated,
                );
              },
              child: Text(dialogContext.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void editSingleImage(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(sheetContext.l10n.takeNewPhoto),
              onTap: () async {
                Navigator.pop(sheetContext);
                await processAndSaveNewImage(
                  context,
                  product,
                  ImageSource.camera,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(sheetContext.l10n.chooseGalleryPhoto),
              onTap: () async {
                Navigator.pop(sheetContext);
                await processAndSaveNewImage(
                  context,
                  product,
                  ImageSource.gallery,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void showProductFormDialog(BuildContext context, {Product? productToEdit}) {
    AdaptiveForm.show(
      context,
      builder: (dialogContext) => ProductFormDialog(
        productToEdit: productToEdit,
        promotionsMap: promotions(),
        categoryNames: categories(),
        onSave: (productModel, isEditing) async {
          if (isEditing) {
            discardPendingStock(productModel.id!);
            await repository.updateProduct(productModel);
          } else {
            await repository.insertProduct(productModel);
          }
          if (!dialogContext.mounted) return;
          reloadProducts();
          AppAlerts.showSuccess(
            dialogContext,
            isEditing
                ? dialogContext.l10n.productUpdated
                : dialogContext.l10n.productCreated,
          );
        },
      ),
    );
  }

  void showProductFieldDialog(
    BuildContext context,
    Product product,
    InventoryProductField field,
  ) {
    late final String title;
    late final String initialValue;
    late final TextInputType keyboardType;
    List<TextInputFormatter>? formatters;
    String? suffix;

    switch (field) {
      case InventoryProductField.name:
        title = context.l10n.fieldName;
        initialValue = product.name;
        keyboardType = TextInputType.text;
      case InventoryProductField.units:
        title = context.l10n.fieldUnits;
        initialValue = product.units.toString();
        keyboardType = TextInputType.number;
        formatters = AppNumbers.integerInputFormatters;
      case InventoryProductField.price:
        title = context.l10n.fieldSalePrice;
        initialValue = context.amountInput(product.price);
        keyboardType = AppNumbers.decimalKeyboard;
        formatters = AppNumbers.decimalInputFormatters;
        suffix = '€';
      case InventoryProductField.cost:
        title = context.l10n.fieldAcquisitionCost;
        initialValue = context.amountInput(product.cost);
        keyboardType = AppNumbers.decimalKeyboard;
        formatters = AppNumbers.decimalInputFormatters;
        suffix = '€';
    }

    showEditSingleFieldDialog(
      context,
      title: title,
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      suffixText: suffix,
      onSave: (value) => saveProductField(context, product, field, value),
    );
  }

  void _showInvalidNumber(BuildContext context) =>
      AppAlerts.showError(context, context.l10n.invalidNumber);

  Future<void> saveProductField(
    BuildContext context,
    Product product,
    InventoryProductField field,
    String value,
  ) async {
    late final String successMessage;
    final id = product.id!;

    switch (field) {
      case InventoryProductField.name:
        if (value.trim().isEmpty) return;
        await repository.updateFields(id, name: value.trim());
        if (!context.mounted) return;
        successMessage = context.l10n.nameUpdated;
      case InventoryProductField.units:
        final units = AppNumbers.parseInt(value);
        if (units == null || units < 0) return _showInvalidNumber(context);
        discardPendingStock(id);
        await repository.updateFields(id, units: units);
        if (!context.mounted) return;
        successMessage = context.l10n.stockUpdated;
      case InventoryProductField.price:
        final price = AppNumbers.parseDecimal(value);
        if (price == null || price < 0) return _showInvalidNumber(context);
        await repository.updateFields(id, price: price);
        if (!context.mounted) return;
        successMessage = context.l10n.salePriceUpdated;
      case InventoryProductField.cost:
        final cost = AppNumbers.parseDecimal(value);
        if (cost == null || cost < 0) return _showInvalidNumber(context);
        await repository.updateFields(id, cost: cost);
        if (!context.mounted) return;
        successMessage = context.l10n.costUpdated;
    }

    Navigator.pop(context);
    reloadProducts();
    AppAlerts.showSuccess(context, successMessage);
  }

  Future<void> editCategory(BuildContext context, Product product) async {
    final pick = await pickCategory(context, currentId: product.categoryId);
    if (pick == null || !context.mounted) {
      if (context.mounted) reloadProducts();
      return;
    }

    await repository.updateFields(
      product.id!,
      categoryId: pick.category?.id,
      clearCategory: pick.category == null,
    );
    if (context.mounted) reloadProducts();
  }
}
