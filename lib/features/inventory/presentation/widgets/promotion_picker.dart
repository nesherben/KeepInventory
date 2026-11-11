import 'package:flutter/material.dart';
import 'package:keepinventory/core/shared_widgets/adaptive_form.dart';
import 'package:keepinventory/core/theme/app_colors.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../promotions/domain/promotion.dart';

/// Resultado de elegir promoción: [promotion] null = "Sin promoción".
class PromotionPick {
  const PromotionPick(this.promotion);
  final Promotion? promotion;
}

/// Panel inferior para elegir la promoción de un producto, con el mismo
/// aspecto que el de categorías: tocar una la aplica, la actual sale marcada
/// y "Quitar promoción" la elimina. Null si se cerró sin elegir.
Future<PromotionPick?> pickPromotion(
  BuildContext context, {
  required List<Promotion> promotions,
  int? currentId,
}) {
  return showModalBottomSheet<PromotionPick>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final colors = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomSafeInset(sheetContext)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.promotionPickTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (promotions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.promotionsEmpty,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    for (final promo in promotions)
                      ListTile(
                        leading: Icon(
                          promo.type == 'bundle_fixed_price'
                              ? Icons.layers
                              : Icons.percent,
                          color: AppColors.warning,
                        ),
                        title: Text(promo.name),
                        subtitle: Text(_summary(sheetContext, promo)),
                        selected: promo.id == currentId,
                        trailing: promo.id == currentId
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () =>
                            Navigator.pop(sheetContext, PromotionPick(promo)),
                      ),
                    if (currentId != null)
                      ListTile(
                        leading: Icon(
                          Icons.remove_circle_outline,
                          color: colors.error,
                        ),
                        title: Text(
                          l10n.promotionRemove,
                          style: TextStyle(color: colors.error),
                        ),
                        onTap: () => Navigator.pop(
                          sheetContext,
                          const PromotionPick(null),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Resumen de la promoción (mismo texto que en la pantalla de Ofertas).
String _summary(BuildContext context, Promotion promo) =>
    promo.type == 'bundle_fixed_price'
    ? context.l10n.promotionBundleSummary(
        promo.threshold.toString(),
        context.amount(promo.discountValue),
      )
    : context.l10n.promotionPercentSummary(
        promo.discountValue.toStringAsFixed(0),
        promo.threshold.toString(),
      );
