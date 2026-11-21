import 'change_entry.dart';

/// Filtros de la pantalla de historial: tipo de elemento, acción, fecha y texto.
class ChangeLogFilter {
  final ChangeEntity? entity;
  final ChangeAction? action;

  /// Solo entradas desde este instante (inclusive). null = cualquier fecha.
  final DateTime? since;
  final String query;

  const ChangeLogFilter({
    this.entity,
    this.action,
    this.since,
    this.query = '',
  });

  /// ¿Hay algún filtro puesto?
  bool get isActive =>
      entity != null ||
      action != null ||
      since != null ||
      query.trim().isNotEmpty;

  ChangeLogFilter copyWith({
    ChangeEntity? entity,
    bool clearEntity = false,
    ChangeAction? action,
    bool clearAction = false,
    DateTime? since,
    bool clearSince = false,
    String? query,
  }) {
    return ChangeLogFilter(
      entity: clearEntity ? null : entity ?? this.entity,
      action: clearAction ? null : action ?? this.action,
      since: clearSince ? null : since ?? this.since,
      query: query ?? this.query,
    );
  }

  bool matches(ChangeEntry entry) {
    if (entity != null && entry.entity != entity) return false;
    if (action != null && entry.action != action) return false;
    if (since != null && entry.createdAt.isBefore(since!)) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return entry.entityName.toLowerCase().contains(q) ||
        _anyValueContains(entry.before, q) ||
        _anyValueContains(entry.after, q);
  }

  /// Respeta el orden recibido.
  List<ChangeEntry> apply(List<ChangeEntry> entries) =>
      entries.where(matches).toList();

  /// Busca el texto en los valores guardados (nombres, categorías, etc.).
  static bool _anyValueContains(Map<String, Object?> values, String q) {
    for (final value in values.values) {
      if (value is String && value.toLowerCase().contains(q)) return true;
      if (value is List &&
          value.any((v) => v.toString().toLowerCase().contains(q))) {
        return true;
      }
    }
    return false;
  }
}
