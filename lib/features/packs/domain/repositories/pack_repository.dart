import '../pack.dart';

abstract class PackRepository {
  Future<List<Pack>> getPacks();
  Future<void> createPack(Pack pack);
  Future<void> updatePack(Pack oldPack, Pack newPack);
  Future<void> deletePack(Pack pack);
}
