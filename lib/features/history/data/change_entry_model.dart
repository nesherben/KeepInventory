import 'dart:convert';

import '../domain/change_entry.dart';

/// Lee una fila de `change_log`. Si alguna columna está dañada devuelve null
/// (esa entrada se omite en vez de romper la pantalla).
class ChangeEntryModel {
  const ChangeEntryModel._();

  static ChangeEntry? fromMap(Map<String, Object?> map) {
    try {
      final entity = ChangeEntity.fromDb(map['entity'] as String?);
      final action = ChangeAction.fromDb(map['action'] as String?);
      if (entity == null || action == null) return null;
      return ChangeEntry(
        id: map['id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        entity: entity,
        entityId: map['entity_id'] as int,
        entityName: (map['entity_name'] as String?) ?? '',
        action: action,
        changedFields: [
          for (final f in jsonDecode(map['changed_fields'] as String) as List)
            f.toString(),
        ],
        before: _decodeMap(map['before_json']),
        after: _decodeMap(map['after_json']),
        undone: (map['undone'] as int? ?? 0) == 1,
        groupId: map['group_id'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, Object?> _decodeMap(Object? raw) {
    final decoded = jsonDecode(raw as String);
    return decoded is Map ? Map<String, Object?>.from(decoded) : const {};
  }
}
