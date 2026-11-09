import '../../domain/combo.dart';
import '../../domain/repositories/combo_repository.dart';
import '../datasources/combo_local_datasource.dart';

class ComboRepositoryImpl implements ComboRepository {
  final ComboLocalDatasource datasource;

  ComboRepositoryImpl(this.datasource);

  @override
  Future<List<Combo>> getCombos() => datasource.getCombos();

  @override
  Future<int> saveCombo(Combo combo) => datasource.saveCombo(combo);

  @override
  Future<void> deleteCombo(int id) => datasource.deleteCombo(id);
}
