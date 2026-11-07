import '../../data/datasources/dashboard_local_datasource.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../sales/domain/payment_method.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDatasource datasource;

  DashboardRepositoryImpl(this.datasource);

  @override
  Future<Map<PaymentMethod, double>> getRevenueByPaymentMethod() async =>
      await datasource.getRevenueByPaymentMethod();

  @override
  Future<Map<String, Map<PaymentMethod, double>>>
  getRevenueByPaymentMethodPerGroup() async =>
      await datasource.getRevenueByPaymentMethodPerGroup();

  @override
  Future<double> getTotalRevenue() async => await datasource.getTotalRevenue();

  @override
  Future<double> getInventoryCost() async =>
      await datasource.getInventoryCost();

  @override
  Future<double> getExpectedRevenue() async =>
      await datasource.getExpectedRevenue();

  @override
  Future<double> getActualNetProfit() async =>
      await datasource.getActualNetProfit();

  @override
  Future<Map<String, double>> getDailySales() async =>
      await datasource.getDailySales();

  @override
  Future<Map<String, double>> getDailyNetProfits() async =>
      await datasource.getDailyNetProfits();
}
