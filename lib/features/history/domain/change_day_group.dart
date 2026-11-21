import 'change_entry.dart';

/// Entradas de un mismo día, para la lista agrupada por fecha.
class ChangeDayGroup {
  /// Medianoche del día.
  final DateTime day;
  final List<ChangeEntry> entries;

  const ChangeDayGroup(this.day, this.entries);
}

/// Agrupa por día manteniendo el orden recibido (de más nuevo a más antiguo):
/// los grupos salen en el orden en que aparece su primer elemento.
List<ChangeDayGroup> groupChangesByDay(List<ChangeEntry> entries) {
  final groups = <DateTime, List<ChangeEntry>>{};
  for (final entry in entries) {
    final d = entry.createdAt;
    groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(entry);
  }
  return [for (final e in groups.entries) ChangeDayGroup(e.key, e.value)];
}

/// Entradas de la misma operación (mismo `groupId`), incluida [entry].
List<ChangeEntry> operationOf(ChangeEntry entry, List<ChangeEntry> all) {
  final id = entry.groupId;
  if (id == null) return [entry];
  return all.where((e) => e.groupId == id).toList();
}
