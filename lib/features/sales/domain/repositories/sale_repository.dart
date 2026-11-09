import '../sale.dart';

abstract class SaleRepository {
  /// Guarda la venta y devuelve su número (id).
  Future<int> processSale(Sale sale);
  Future<List<Sale>> getSales();
  Future<void> refundSale(Sale sale);
  Future<void> processPartialRefund({
    required Sale originalSale,
    required Map<SaleItem, int> itemsToRefund,
    required Map<SalePackItem, int> packsToRefund,
    required bool restockAsComponents,
    required double customRefundAmount,
  });
  Future<void> updateFairNameForDate(String datePrefix, String? fairName);
  Future<List<String>> getAvailableFairs();
  Future<void> reassignFair(String fairName, String? newFairName);
  Future<int> countSalesForFair(String fairName);
  Future<void> deleteFair(String fairName);
}
