/// El stock en la BD no alcanza para la venta (cambió desde que se llenó el
/// carrito: sincronización, restauración de una copia, otra edición…).
class InsufficientStockException implements Exception {
  /// Nombre del producto o pack que no alcanza.
  final String name;

  const InsufficientStockException(this.name);

  @override
  String toString() => 'InsufficientStockException($name)';
}
