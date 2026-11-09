import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';
import 'package:keepinventory/core/services/image_compression_service.dart';

import '../../domain/product.dart';
import '../../data/product_model.dart';
import '../../../promotions/domain/promotion.dart';
import 'category_picker.dart';
import '../../../../core/shared_widgets/adaptive_form.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? productToEdit;
  final Map<int, Promotion> promotionsMap;

  /// Nombres de las categorías por id (para mostrar la actual).
  final Map<int, String> categoryNames;

  /// Guarda el producto; el diálogo se cierra solo después.
  final Future<void> Function(ProductModel product, bool isEditing) onSave;

  const ProductFormDialog({
    super.key,
    this.productToEdit,
    required this.promotionsMap,
    required this.onSave,
    this.categoryNames = const {},
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late String _name;
  late int _units;
  late double _price;
  late double _cost;
  int? _selectedPromotionId;
  int? _categoryId;
  String? _categoryName;
  Uint8List? _selectedImageBytes;
  String? _oldImagePath;

  /// Precio y coste mientras se escriben (para el margen en vivo).
  double? _livePrice;
  double? _liveCost;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _name = p?.name ?? '';
    _units = p?.units ?? 0;
    _price = p?.price ?? 0.0;
    _cost = p?.cost ?? 0.0;
    _selectedPromotionId = p?.promotionId;
    _categoryId = p?.categoryId;
    _categoryName = widget.categoryNames[p?.categoryId];
    _selectedImageBytes = p?.imageBytes;
    _oldImagePath = p?.imagePath;
    _livePrice = p?.price;
    _liveCost = p?.cost;
  }

  Future<void> _pickAndCompressImage() async {
    final source = await _showImageSourcePicker();
    if (source != null) await _processImage(source);
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(sheetContext.l10n.camera),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(sheetContext.l10n.gallery),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final compressed = await ImageCompressionService.compressFile(
      File(pickedFile.path),
    );
    if (!mounted) return;

    setState(() {
      _selectedImageBytes = compressed;
      _oldImagePath = null;
    });
  }

  ProductModel _createProductModel() {
    return ProductModel(
      id: widget.productToEdit?.id,
      name: _name,
      units: _units,
      price: _price,
      cost: _cost,
      imagePath: _oldImagePath,
      imageBytes: _selectedImageBytes,
      promotionId: _selectedPromotionId,
      categoryId: _categoryId,
    );
  }

  Future<void> _pickCategory() async {
    final pick = await pickCategory(context, currentId: _categoryId);
    if (pick == null || !mounted) return;
    setState(() {
      _categoryId = pick.category?.id;
      _categoryName = pick.category?.name;
    });
  }

  Future<void> _saveProduct() async {
    if (_saving) return;
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();

    final isEditing = widget.productToEdit != null;
    setState(() => _saving = true);
    try {
      await widget.onSave(_createProductModel(), isEditing);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) Navigator.pop(context);
  }

  /// Vacío → "Requerido"; no numérico o negativo → "número no válido".
  String? _validateNumber(String? value, {bool integer = false}) {
    if (value == null || value.trim().isEmpty) return context.l10n.required;
    final parsed = integer
        ? AppNumbers.parseInt(value)?.toDouble()
        : AppNumbers.parseDecimal(value);
    if (parsed == null || parsed < 0) return context.l10n.invalidNumber;
    return null;
  }

  /// "Margen por unidad: 2,50 € (42 %)" en vivo; en rojo si hay pérdidas.
  Widget _buildMarginHint() {
    final price = _livePrice;
    final cost = _liveCost;
    if (price == null || cost == null || price <= 0) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final margin = price - cost;
    final loss = margin < 0;
    return Row(
      children: [
        Icon(
          loss ? Icons.trending_down : Icons.trending_up,
          size: 18,
          color: loss ? colors.error : colors.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            loss
                ? context.l10n.productFormLoss(context.amount(-margin))
                : context.l10n.productFormMargin(
                    context.amount(margin),
                    context.percent(margin / price * 100),
                  ),
            style: TextStyle(
              fontSize: 13,
              color: loss ? colors.error : colors.onSurfaceVariant,
              fontWeight: loss ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: _pickAndCompressImage,
        child: Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            image: _selectedImageBytes != null
                ? DecorationImage(
                    image: MemoryImage(_selectedImageBytes!),
                    fit: BoxFit.cover,
                  )
                : (_oldImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(_oldImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null),
          ),
          child: _selectedImageBytes == null && _oldImagePath == null
              ? Icon(
                  Icons.add_a_photo,
                  size: 40,
                  color: colors.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final isSheet = AdaptiveForm.isSingleColumn(context);
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    // Móvil: campos a todo el ancho. Tablet apaisada: dos columnas.
    const dialogWidth = 760.0;
    final fieldWidth = isSheet
        ? double.infinity
        : isLandscape
        ? (dialogWidth - 12) / 2
        : dialogWidth;

    Widget field(Widget child) => SizedBox(width: fieldWidth, child: child);

    return AdaptiveFormScaffold(
      title: isEditing
          ? context.l10n.productFormEditTitle
          : context.l10n.productFormNewTitle,
      dialogWidth: dialogWidth,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _saveProduct,
          child: Text(isEditing ? context.l10n.update : context.l10n.save),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          // Orden de uso: nombre → precio → coste (margen) → unidades.
          // "Siguiente" en el teclado salta de campo; el último guarda.
          children: [
            field(_buildImagePicker()),
            field(
              TextFormField(
                initialValue: _name,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.l10n.productName,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.l10n.required
                    : null,
                onSaved: (v) => _name = v!.trim(),
              ),
            ),
            field(
              CategoryField(categoryName: _categoryName, onTap: _pickCategory),
            ),
            field(
              TextFormField(
                initialValue: _price == 0.0 ? '' : context.amountInput(_price),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.l10n.salePrice,
                  suffixText: '€',
                ),
                keyboardType: AppNumbers.decimalKeyboard,
                inputFormatters: AppNumbers.decimalInputFormatters,
                validator: _validateNumber,
                onChanged: (v) =>
                    setState(() => _livePrice = AppNumbers.parseDecimal(v)),
                onSaved: (v) => _price = AppNumbers.parseDecimal(v)!,
              ),
            ),
            field(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _cost == 0.0
                        ? ''
                        : context.amountInput(_cost),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: context.l10n.acquisitionCost,
                      suffixText: '€',
                    ),
                    keyboardType: AppNumbers.decimalKeyboard,
                    inputFormatters: AppNumbers.decimalInputFormatters,
                    validator: _validateNumber,
                    onChanged: (v) =>
                        setState(() => _liveCost = AppNumbers.parseDecimal(v)),
                    onSaved: (v) => _cost = AppNumbers.parseDecimal(v)!,
                  ),
                  const SizedBox(height: 6),
                  _buildMarginHint(),
                ],
              ),
            ),
            field(
              TextFormField(
                initialValue: isEditing || _units != 0 ? _units.toString() : '',
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: context.l10n.unitsInStock,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: AppNumbers.integerInputFormatters,
                validator: (v) => _validateNumber(v, integer: true),
                onSaved: (v) => _units = AppNumbers.parseInt(v)!,
                onFieldSubmitted: (_) => _saveProduct(),
              ),
            ),
            field(
              DropdownButtonFormField<int?>(
                initialValue: _selectedPromotionId,
                decoration: InputDecoration(
                  labelText: context.l10n.appliedPromotion,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.l10n.noPromotion),
                  ),
                  ...widget.promotionsMap.values.map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedPromotionId = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
