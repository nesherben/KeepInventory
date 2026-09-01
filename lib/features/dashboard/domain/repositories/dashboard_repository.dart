abstract class DashboardRepository {
  Future<double> getTotalRevenue();
  Future<double> getInventoryCost();
  Future<double> getExpectedRevenue();
  Future<double> getActualNetProfit();
  Future<Map<String, double>> getDailySales();
  Future<Map<String, double>> getDailyNetProfits();
}
