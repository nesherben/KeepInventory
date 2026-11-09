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
}
