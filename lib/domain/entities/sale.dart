class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String? productName; // Añadido para mostrar en el historial
  final int quantity;
  final double historicalPrice;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.historicalPrice,
  });
}

class SalePackItem {
  final int? id;
  final int saleId;
  final int packId;
  final String packName;
  final int quantity;
  final double historicalPrice;

  SalePackItem({
    this.id,
    required this.saleId,
    required this.packId,
    required this.packName,
    required this.quantity,
    required this.historicalPrice,
  });
}

class Sale {
  final int? id;
  final DateTime date;
  final double totalAmount;
  final String? fairName;
  final List<SaleItem> items;
  final List<SalePackItem> packItems; // <--- Nuevo para los packs vendidos

  Sale({
    this.id,
    required this.date,
    required this.totalAmount,
    this.fairName,
    required this.items,
    this.packItems = const [],
  });
}
