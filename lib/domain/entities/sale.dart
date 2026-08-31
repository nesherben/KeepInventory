class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final int quantity;
  final double historicalPrice;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.quantity,
    required this.historicalPrice,
  });
}

class Sale {
  final int? id;
  final DateTime date;
  final double totalAmount;
  final List<SaleItem> items;

  Sale({
    this.id,
    required this.date,
    required this.totalAmount,
    this.items = const [],
  });
}
