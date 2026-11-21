import '../../domain/change_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDatasource datasource;

  HistoryRepositoryImpl(this.datasource);

  @override
  Future<List<ChangeEntry>> getEntries() => datasource.getEntries();
}
