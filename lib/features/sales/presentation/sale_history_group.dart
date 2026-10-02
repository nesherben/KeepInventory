import '../domain/sale.dart';

class SaleHistoryGroup {
  const SaleHistoryGroup({
    required this.key,
    required this.datePrefix,
    required this.sales,
  });

  final String key;
  final String datePrefix;
  final List<Sale> sales;

  bool get isFair => key.startsWith('🎪');

  String get fairName => isFair ? key.replaceFirst('🎪 ', '') : '';

  double get total => sales.fold(0, (sum, sale) => sum + sale.totalAmount);
}

List<SaleHistoryGroup> filterAndGroupSales(
  List<Sale> sales,
  String searchQuery,
) {
  final query = searchQuery.toLowerCase();
  final filteredSales = sales.where((sale) {
    final matchesFair =
        sale.fairName != null && sale.fairName!.toLowerCase().contains(query);
    final matchesTicketId = sale.id.toString().contains(query);
    final matchesItem = sale.items.any(
      (item) => (item.productName ?? '').toLowerCase().contains(query),
    );
    final matchesPack = sale.packItems.any(
      (pack) => (pack.packName ?? '').toLowerCase().contains(query),
    );

    return matchesFair || matchesTicketId || matchesItem || matchesPack;
  });

  final groupedSales = <String, List<Sale>>{};
  final groupDatePrefixes = <String, String>{};
  for (final sale in filteredSales) {
    final day = sale.date.day.toString().padLeft(2, '0');
    final month = sale.date.month.toString().padLeft(2, '0');
    final year = sale.date.year.toString();
    final dateKey = '$day/$month/$year';
    final datePrefix = '$year-$month-$day';
    final groupKey = sale.fairName != null && sale.fairName!.isNotEmpty
        ? '🎪 ${sale.fairName}'
        : '📅 $dateKey';

    groupedSales.putIfAbsent(groupKey, () => []).add(sale);
    groupDatePrefixes[groupKey] = datePrefix;
  }

  return [
    for (final entry in groupedSales.entries)
      SaleHistoryGroup(
        key: entry.key,
        datePrefix: groupDatePrefixes[entry.key]!,
        sales: entry.value,
      ),
  ];
}
