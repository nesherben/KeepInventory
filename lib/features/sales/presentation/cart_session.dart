import '../domain/manual_line_discount.dart';
import '../domain/payment_method.dart';

/// Carrito en curso, en memoria, para que no se pierda al moverse entre
/// pantallas (la caja se destruye al abrir otra desde el menú).
///
/// Guarda ids y cantidades, no los productos: al volver, la caja los busca de
/// nuevo en el catálogo (con el stock actual). Se pierde al cerrar la app.
class CartSession {
  CartSession._();

  static final CartSession instance = CartSession._();

  Map<int, int> products = {};
  Map<int, int> packs = {};
  Map<int, ManualLineDiscount> lineDiscounts = {};
  double adjustmentFactor = 1.0;
  PaymentMethod paymentMethod = PaymentMethod.defaultMethod;

  bool get isEmpty => products.isEmpty && packs.isEmpty;

  void clear() {
    products = {};
    packs = {};
    lineDiscounts = {};
    adjustmentFactor = 1.0;
    paymentMethod = PaymentMethod.defaultMethod;
  }
}
