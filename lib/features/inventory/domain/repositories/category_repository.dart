import '../product_category.dart';

abstract class CategoryRepository {
  Future<List<ProductCategory>> getCategories();

  /// Devuelve la categoría con ese nombre, creándola si no existe.
  Future<ProductCategory> getOrCreate(String name);

  /// Borra la categoría: sus productos se quedan sin categoría y los huecos
  /// de combo de esa categoría desaparecen.
  Future<void> delete(int id);

  Future<int> countProducts(int id);

  /// false si ya existe otra categoría con ese nombre.
  Future<bool> rename(int id, String name);

  /// Nº de productos de cada categoría (por id).
  Future<Map<int, int>> countAll();

  /// Mete [add] en la categoría y saca [remove].
  Future<void> setProducts(
    int id, {
    required Set<int> add,
    required Set<int> remove,
  });
}
