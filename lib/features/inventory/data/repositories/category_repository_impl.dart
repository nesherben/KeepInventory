import '../../domain/product_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDatasource datasource;

  CategoryRepositoryImpl(this.datasource);

  @override
  Future<List<ProductCategory>> getCategories() => datasource.getCategories();

  @override
  Future<ProductCategory> getOrCreate(String name) =>
      datasource.getOrCreate(name);

  @override
  Future<void> delete(int id) => datasource.delete(id);

  @override
  Future<int> countProducts(int id) => datasource.countProducts(id);

  @override
  Future<bool> rename(int id, String name) => datasource.rename(id, name);

  @override
  Future<Map<int, int>> countAll() => datasource.countAll();

  @override
  Future<void> setProducts(
    int id, {
    required Set<int> add,
    required Set<int> remove,
  }) => datasource.setProducts(id, add: add, remove: remove);
}
