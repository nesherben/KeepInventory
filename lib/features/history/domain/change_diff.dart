import 'dart:convert';

import 'change_entry.dart';

/// Resultado de comparar dos versiones de un elemento.
class ChangeDiff {
  /// Campos de configuración que cambian, en orden estable.
  final List<String> changedFields;
  final Map<String, Object?> before;
  final Map<String, Object?> after;

  const ChangeDiff({
    required this.changedFields,
    required this.before,
    required this.after,
  });
}

/// Qué campos de cada elemento cuentan como "configuración". Las cantidades
/// (stock) NO entran: para eso está el control de stock.
abstract final class ChangeTracking {
  /// Clave del campo "la imagen cambió" (no se guardan los bytes).
  static const imageField = 'image';

  static const trackedFields = <ChangeEntity, List<String>>{
    ChangeEntity.product: [
      'name',
      'price',
      'cost',
      'category_id',
      'promotion_id',
      imageField,
    ],
    ChangeEntity.category: ['name'],
    ChangeEntity.promotion: ['name', 'type', 'threshold', 'discount_value'],
    ChangeEntity.pack: ['name', 'price', 'items', imageField],
    ChangeEntity.combo: ['name', 'price', 'slots'],
  };

  /// Compara [before] y [after] solo en los campos de [entity].
  ///
  /// - Creación ([before] null): todos los campos con valor, solo en `after`.
  /// - Borrado ([after] null): todos los campos con valor, solo en `before`.
  /// - Edición: solo los campos que cambian. Devuelve null si no cambia
  ///   ninguno (p. ej. solo se tocó el stock): no hay nada que registrar.
  static ChangeDiff? diff(
    ChangeEntity entity, {
    Map<String, Object?>? before,
    Map<String, Object?>? after,
  }) {
    final fields = trackedFields[entity] ?? const <String>[];
    if (before == null && after == null) return null;

    if (before == null || after == null) {
      final source = (before ?? after)!;
      final values = <String, Object?>{
        for (final f in fields)
          if (source[f] != null) f: source[f],
      };
      return ChangeDiff(
        changedFields: values.keys.toList(),
        before: before == null ? const {} : values,
        after: after == null ? const {} : values,
      );
    }

    final changed = <String>[];
    final oldValues = <String, Object?>{};
    final newValues = <String, Object?>{};
    for (final f in fields) {
      if (_same(before[f], after[f])) continue;
      changed.add(f);
      oldValues[f] = before[f];
      newValues[f] = after[f];
    }
    if (changed.isEmpty) return null;
    return ChangeDiff(
      changedFields: changed,
      before: oldValues,
      after: newValues,
    );
  }

  /// Igualdad en profundidad (listas y mapas de configuración) comparando su
  /// forma JSON, que es la que se guarda.
  static bool _same(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a is num && b is num) return a == b;
    try {
      return jsonEncode(a) == jsonEncode(b);
    } catch (_) {
      return a == b;
    }
  }
}
