import '../change_entry.dart';

abstract class HistoryRepository {
  /// Todas las entradas, de la más nueva a la más antigua.
  Future<List<ChangeEntry>> getEntries();
}
