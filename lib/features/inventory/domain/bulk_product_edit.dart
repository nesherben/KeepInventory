import 'product.dart';

/// Cómo se cambia un número (precio o coste) en una edición múltiple.
enum BulkNumberMode {
  /// No se toca.
  keep,

  /// El mismo valor para todos.
  set,

  /// Sube o baja un porcentaje (negativo = baja).
  percent,

  /// Suma o resta un importe (negativo = resta).
  amount,
}

/// Cambio de un número (precio o coste).
class BulkNumberEdit {
  final BulkNumberMode mode;
  final double value;

  const BulkNumberEdit(this.mode, [this.value = 0]);

  const BulkNumberEdit.keep() : this(BulkNumberMode.keep);

  bool get isKeep => mode == BulkNumberMode.keep;

  /// Valor nuevo a partir de [current]: nunca baja de 0 y va a céntimos.
  double apply(double current) {
    final result = switch (mode) {
      BulkNumberMode.keep => current,
      BulkNumberMode.set => value,
      BulkNumberMode.percent => current * (1 + value / 100),
      BulkNumberMode.amount => current + value,
    };
    if (!result.isFinite) return current;
    final cents = (result * 100).round() / 100;
    return cents < 0 ? 0 : cents;
  }
}

/// Cambios a aplicar a varios productos a la vez (categoría, promoción,
/// precio y coste). Lo que no se marca no se toca; las cantidades (stock)
/// quedan fuera a propósito.
class BulkProductEdit {
  /// true = cambiar la categoría a [categoryId] (null = dejarla sin categoría).
  final bool changeCategory;
  final int? categoryId;

  /// true = cambiar la promoción a [promotionId] (null = quitarla).
  final bool changePromotion;
  final int? promotionId;

  final BulkNumberEdit price;
  final BulkNumberEdit cost;

  const BulkProductEdit({
    this.changeCategory = false,
    this.categoryId,
    this.changePromotion = false,
    this.promotionId,
    this.price = const BulkNumberEdit.keep(),
    this.cost = const BulkNumberEdit.keep(),
  });

  /// ¿No cambia nada?
  bool get isEmpty =>
      !changeCategory && !changePromotion && price.isKeep && cost.isKeep;

  /// Columnas de `products` que cambian para [product].
  Map<String, Object?> valuesFor(Product product) => {
    if (changeCategory) 'category_id': categoryId,
    if (changePromotion) 'promotion_id': promotionId,
    if (!price.isKeep) 'price': price.apply(product.price),
    if (!cost.isKeep) 'cost': cost.apply(product.cost),
  };
}
