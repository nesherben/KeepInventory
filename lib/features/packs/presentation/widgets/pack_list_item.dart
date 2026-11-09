import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../inventory/domain/inventory_view.dart';
import '../../../sales/presentation/widgets/sales_ui_utils.dart';
import '../../domain/pack.dart';
import '../../../inventory/domain/product.dart';

/// Pack en la lista de gestión: imagen, nombre, precio, unidades montadas
/// (ajuste rápido + / −), acciones y, desplegado, sus componentes.
class PackListItem extends StatelessWidget {
  final Pack pack;
  final Function(Pack) onEdit;
  final Function(Pack) onDelete;
  final Function(Pack, int) onQuickAdjust;

  /// Productos por id: precio por separado (ahorro) y stock de componentes.
  final Map<int, Product> products;

  const PackListItem({
    super.key,
    required this.pack,
    required this.onEdit,
    required this.onDelete,
    required this.onQuickAdjust,
    this.products = const {},
  });

  /// Lo que costarían sus componentes sueltos.
  double get _separatePrice => pack.items.fold(
    0.0,
    (t, i) => t + (products[i.productId]?.price ?? 0) * i.quantity,
  );

  /// Cuántos packs más se pueden montar con el stock de los componentes.
  int get _canAssemble {
    if (pack.items.isEmpty) return 0;
    var max = -1;
    for (final item in pack.items) {
      final units = products[item.productId]?.units ?? 0;
      final possible = item.quantity <= 0 ? 0 : units ~/ item.quantity;
      if (max < 0 || possible < max) max = possible;
    }
    return max < 0 ? 0 : max;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          leading: Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: buildPackImage(pack),
          ),
          title: Text(
            pack.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.money(pack.price),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (_separatePrice - pack.price > 0.005)
                  Text(
                    context.l10n.comboSaving(
                      context.amount(_separatePrice - pack.price),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                // Control rápido de unidades montadas
                QuantityStepper(
                  label: context.l10n.packUnitCount(pack.units),
                  isEmpty: pack.units <= 0,
                  isLow: StockLevel.of(pack.units) == StockLevel.low,
                  onDecrement: pack.units > 0
                      ? () => onQuickAdjust(pack, -1)
                      : null,
                  onIncrement: () => onQuickAdjust(pack, 1),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colors.onSurfaceVariant),
                onPressed: () => onEdit(pack),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colors.error),
                onPressed: () => onDelete(pack),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: AppSpacing.xs),
                  SectionLabel(context.l10n.packComponentsPerUnit),
                  const SizedBox(height: AppSpacing.sm),
                  ...pack.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              item.productName ?? context.l10n.unknownDeleted,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Stock del componente (rojo si no da para otro)
                          Text(
                            context.l10n.packComponentStock(
                              products[item.productId]?.units ?? 0,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  (products[item.productId]?.units ?? 0) <
                                      item.quantity
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            context.l10n.packComponentCount(
                              item.quantity.toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        _canAssemble > 0
                            ? Icons.construction_outlined
                            : Icons.block_outlined,
                        size: 16,
                        color: _canAssemble > 0 ? colors.primary : colors.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _canAssemble > 0
                              ? context.l10n.packCanAssemble(_canAssemble)
                              : context.l10n.packCannotAssemble,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
