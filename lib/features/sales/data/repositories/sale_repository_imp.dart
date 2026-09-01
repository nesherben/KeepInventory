import '../../data/datasources/sale_local_datasource.dart';
import '../../domain/sale.dart';
import '../../domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleLocalDatasource datasource;

  SaleRepositoryImpl(this.datasource);

  @override
  Future<void> processSale(Sale sale) async =>
      await datasource.processSale(sale);

  @override
  Future<List<Sale>> getSales() async => await datasource.getSales();

  @override
  Future<void> refundSale(Sale sale) async => await datasource.refundSale(sale);

  @override
  Future<void> processPartialRefund({
    required Sale originalSale,
    required Map<SaleItem, int> itemsToRefund,
    required Map<SalePackItem, int> packsToRefund,
    required bool restockPacks,
    required double customRefundAmount,
  }) async {
    await datasource.processPartialRefund(
      originalSale: originalSale,
      itemsToRefund: itemsToRefund,
      packsToRefund: packsToRefund,
      restockPacks: restockPacks,
      customRefundAmount: customRefundAmount,
    );
  }

  @override
  Future<void> updateFairNameForDate(
    String datePrefix,
    String? fairName,
  ) async {
    await datasource.updateFairNameForDate(datePrefix, fairName);
  }

  @override
  Future<List<String>> getAvailableFairs() async =>
      await datasource.getAvailableFairs();
}
