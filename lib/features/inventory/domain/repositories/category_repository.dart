import '../product_category.dart';

abstract class CategoryRepository {
  Future<List<ProductCategory>> getCategories();

  /// Devuelve la categoría con ese nombre, creándola si no existe.
  Future<ProductCategory> getOrCreate(String name);

  /// Borra la categoría: sus productos se quedan sin categoría y los huecos
  /// de combo de esa categoría desaparecen.
  Future<void> delete(int id);

  Future<int> countProducts(int id);
}
