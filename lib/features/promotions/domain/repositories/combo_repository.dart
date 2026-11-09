import '../combo.dart';

abstract class ComboRepository {
  Future<List<Combo>> getCombos();
  Future<int> saveCombo(Combo combo);
  Future<void> deleteCombo(int id);
}
