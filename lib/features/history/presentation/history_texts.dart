import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/change_entry.dart';

/// Textos, iconos y colores del historial. Todo lo que ve el usuario sale de
/// aquí para que la lista, el detalle y los filtros hablen igual.
extension HistoryTexts on BuildContext {
  /// "Producto", "Categoría"…
  String historyKind(ChangeEntity entity) => switch (entity) {
    ChangeEntity.product => l10n.historyKindProduct,
    ChangeEntity.category => l10n.historyKindCategory,
    ChangeEntity.pack => l10n.historyKindPack,
    ChangeEntity.promotion => l10n.historyKindPromotion,
    ChangeEntity.combo => l10n.historyKindCombo,
  };

  /// "Productos", "Categorías"… (para los filtros)
  String historyKindPlural(ChangeEntity entity) => switch (entity) {
    ChangeEntity.product => l10n.historyEntityProducts,
    ChangeEntity.category => l10n.historyEntityCategories,
    ChangeEntity.pack => l10n.historyEntityPacks,
    ChangeEntity.promotion => l10n.historyEntityPromotions,
    ChangeEntity.combo => l10n.historyEntityCombos,
  };

  String historyAction(ChangeAction action) => switch (action) {
    ChangeAction.create => l10n.historyActionCreated,
    ChangeAction.update => l10n.historyActionEdited,
    ChangeAction.delete => l10n.historyActionDeleted,
  };

  /// "Precio", "Categoría"… a partir de la columna guardada.
  String historyField(String field) => switch (field) {
    'name' => l10n.historyFieldName,
    'price' => l10n.historyFieldPrice,
    'cost' => l10n.historyFieldCost,
    'category_id' => l10n.historyFieldCategory,
    'promotion_id' => l10n.historyFieldPromotion,
    ChangeFieldKeys.image => l10n.historyFieldImage,
    'items' => l10n.historyFieldItems,
    'slots' => l10n.historyFieldSlots,
    'type' => l10n.historyFieldType,
    'threshold' => l10n.historyFieldThreshold,
    'discount_value' => l10n.historyFieldDiscount,
    _ => field,
  };

  /// El valor de [field] en [values] (el antes o el después), legible.
  String historyValue(String field, Map<String, Object?> values) {
    final value = values[field];
    switch (field) {
      case 'price' || 'cost':
        return value is num ? money(value.toDouble()) : '—';
      case 'category_id':
        return (values['category'] as String?) ?? l10n.historyNone;
      case 'promotion_id':
        return (values['promotion'] as String?) ?? l10n.historyNone;
      case ChangeFieldKeys.image:
        return value == true ? l10n.historyImageYes : l10n.historyImageNo;
      case 'items':
        final items = value is List ? value : const [];
        return items
            .map(
              (i) => i is Map ? '${i['quantity']}× ${i['name'] ?? '?'}' : '?',
            )
            .join(', ');
      case 'slots':
        final slots = value is List ? value : const [];
        return slots.map((s) => s is Map ? '${s['name']}' : '?').join(', ');
      case 'type':
        return switch (value) {
          'percentage' => l10n.historyPromoTypePercent,
          'bundle_fixed_price' => l10n.historyPromoTypeBundle,
          _ => '$value',
        };
      case 'discount_value':
        if (value is! num) return '—';
        // El tipo solo se conoce si cambió en la misma entrada
        return values['type'] == 'percentage'
            ? percent(value.toDouble(), maxDecimals: 2)
            : amount(value.toDouble());
      default:
        return value == null ? '—' : '$value';
    }
  }

  /// "Precio: 10,00 € → 12,00 €" para la fila de una edición.
  String historyChangeSummary(ChangeEntry entry, String field) =>
      '${historyField(field)}: ${historyValue(field, entry.before)} → '
      '${historyValue(field, entry.after)}';

  /// Hoy / Ayer / 20/11/2026 (siempre día/mes/año, como los tickets).
  String historyDayLabel(DateTime day, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    final diff = d0.difference(day).inDays;
    if (diff == 0) return l10n.historyDateToday;
    if (diff == 1) return l10n.historyDateYesterday;
    return '${_two(day.day)}/${_two(day.month)}/${day.year}';
  }

  String historyTime(DateTime date) =>
      '${_two(date.hour)}:${_two(date.minute)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// Claves de campo con significado especial.
abstract final class ChangeFieldKeys {
  static const image = 'image';
}

/// Icono según el tipo de elemento.
IconData historyEntityIcon(ChangeEntity entity) => switch (entity) {
  ChangeEntity.product => Icons.inventory_2_outlined,
  ChangeEntity.category => Icons.category_outlined,
  ChangeEntity.pack => Icons.card_giftcard_outlined,
  ChangeEntity.promotion => Icons.local_offer_outlined,
  ChangeEntity.combo => Icons.extension_outlined,
};

/// Color según la acción: verde crear, azul editar y rojo borrar (el rojo se
/// reserva a borrar). Lo deshecho va en ámbar.
Color historyActionColor(ChangeAction action, {bool undone = false}) {
  if (undone) return AppColors.warning;
  return switch (action) {
    ChangeAction.create => AppColors.success,
    ChangeAction.update => AppColors.info,
    ChangeAction.delete => AppColors.danger,
  };
}
