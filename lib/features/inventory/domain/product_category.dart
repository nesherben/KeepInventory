/// Categoría de producto ("Camisetas", "Tazas"…). Independiente de las
/// promociones: sirve para filtrar y para huecos de combo por categoría.
class ProductCategory {
  final int id;
  final String name;

  const ProductCategory({required this.id, required this.name});
}
