/// Elemento de configuración al que se refiere una entrada del historial.
enum ChangeEntity {
  product('product'),
  category('category'),
  pack('pack'),
  promotion('promotion'),
  combo('combo');

  const ChangeEntity(this.dbValue);

  /// Valor guardado en `change_log.entity`.
  final String dbValue;

  static ChangeEntity? fromDb(String? value) {
    for (final entity in values) {
      if (entity.dbValue == value) return entity;
    }
    return null;
  }
}

/// Qué se hizo con el elemento.
enum ChangeAction {
  create('create'),
  update('update'),
  delete('delete');

  const ChangeAction(this.dbValue);

  /// Valor guardado en `change_log.action`.
  final String dbValue;

  static ChangeAction? fromDb(String? value) {
    for (final action in values) {
      if (action.dbValue == value) return action;
    }
    return null;
  }
}

/// Una entrada del historial de cambios de configuración.
///
/// [before] y [after] solo llevan los campos que cambian ([changedFields]);
/// en una creación solo hay [after] y en un borrado solo [before]. Los campos
/// que apuntan a otro elemento (categoría, promoción) guardan también su
/// nombre legible, para que la entrada se entienda aunque se borre después.
class ChangeEntry {
  final int? id;
  final DateTime createdAt;
  final ChangeEntity entity;
  final int entityId;
  final String entityName;
  final ChangeAction action;
  final List<String> changedFields;
  final Map<String, Object?> before;
  final Map<String, Object?> after;

  /// true = ya se deshizo (se puede rehacer mientras no haya un cambio nuevo).
  final bool undone;

  /// Entradas de una misma operación (p. ej. asignar una promoción a toda una
  /// categoría) comparten grupo.
  final String? groupId;

  const ChangeEntry({
    this.id,
    required this.createdAt,
    required this.entity,
    required this.entityId,
    required this.entityName,
    required this.action,
    this.changedFields = const [],
    this.before = const {},
    this.after = const {},
    this.undone = false,
    this.groupId,
  });
}
