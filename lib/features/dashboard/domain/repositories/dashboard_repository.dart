import '../../../sales/domain/payment_method.dart';

abstract class DashboardRepository {
  Future<double> getTotalRevenue();
  Future<Map<PaymentMethod, double>> getRevenueByPaymentMethod();
  Future<Map<String, Map<PaymentMethod, double>>>
  getRevenueByPaymentMethodPerGroup();
  Future<double> getInventoryCost();
  Future<double> getExpectedRevenue();
  Future<double> getActualNetProfit();
  Future<Map<String, double>> getDailySales();
  Future<Map<String, double>> getDailyNetProfits();
}
