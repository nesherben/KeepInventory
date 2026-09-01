import '../sale.dart';

abstract class SaleRepository {
  Future<void> processSale(Sale sale);
  Future<List<Sale>> getSales();
  Future<void> refundSale(Sale sale);
  Future<void> processPartialRefund({
    required Sale originalSale,
    required Map<SaleItem, int> itemsToRefund,
    required Map<SalePackItem, int> packsToRefund,
    required bool restockPacks,
    required double customRefundAmount,
  });
  Future<void> updateFairNameForDate(String datePrefix, String? fairName);
  Future<List<String>> getAvailableFairs();
}
