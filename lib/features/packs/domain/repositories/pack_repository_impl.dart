import '../../data/datasources/pack_local_datasource.dart';
import '../../domain/pack.dart';
import '../../domain/repositories/pack_repository.dart';

class PackRepositoryImpl implements PackRepository {
  final PackLocalDatasource datasource;

  PackRepositoryImpl(this.datasource);

  @override
  Future<List<Pack>> getPacks() async {
    return await datasource.getPacks();
  }

  @override
  Future<void> createPack(Pack pack) async {
    await datasource.createPack(pack);
  }

  @override
  Future<void> updatePack(Pack oldPack, Pack newPack) async {
    await datasource.updatePack(oldPack, newPack);
  }

  @override
  Future<void> deletePack(Pack pack) async {
    await datasource.deletePack(pack);
  }
}
