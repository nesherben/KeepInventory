import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inventory/domain/inventory_view.dart';
import '../../../inventory/domain/product.dart';
import '../../../sales/domain/sale.dart';

/// Resumen del Inicio en móvil: tarjetas compactas con icono, de dos en dos.
/// Al tocar una sale una ficha con qué significa la cifra (y, en stock y
/// tickets, el detalle con un acceso a la pantalla completa).
class DashboardSummaryGrid extends StatelessWidget {
  const DashboardSummaryGrid({
    super.key,
    required this.inventoryCost,
    required this.expectedRevenue,
    required this.netProfit,
    required this.lowStock,
    required this.lowStockCount,
    required this.recentSales,
    required this.onOpenTickets,
    required this.onOpenInventory,
    this.hideAmounts = false,
    this.firstTileKey,
  });

  final double inventoryCost;
  final double expectedRevenue;
  final double netProfit;

  /// Los productos con menos stock (para el detalle) y cuántos hay en total.
  final List<Product> lowStock;
  final int lowStockCount;
  final List<Sale> recentSales;
  final VoidCallback onOpenTickets;
  final VoidCallback onOpenInventory;

  /// Modo privacidad: los importes se ocultan.
  final bool hideAmounts;

  /// Clave de la primera fila (la usa la guía de la pantalla).
  final Key? firstTileKey;

  String _money(BuildContext context, double value) =>
      hideAmounts ? '•••••• €' : context.money(value);

  /// Ficha con la explicación de una cifra, y opcionalmente su detalle.
  void _showInfo(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String info,
    List<Widget> details = const [],
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(icon, color: color, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              info,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ...details,
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onAction();
                },
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String left, String right, {Color? rightColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(left, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text(
          right,
          style: TextStyle(fontWeight: FontWeight.w700, color: rightColor),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final lastSale = recentSales.isEmpty ? null : recentSales.first;
    final hasOut = lowStock.any(
      (p) => StockLevel.of(p.units) == StockLevel.out,
    );

    final tiles = <_SummaryTile>[
      _SummaryTile(
        icon: Icons.inventory_2_outlined,
        color: AppColors.warning,
        label: l10n.metricInventoryCost,
        value: _money(context, inventoryCost),
        onTap: () => _showInfo(
          context,
          icon: Icons.inventory_2_outlined,
          color: AppColors.warning,
          title: l10n.metricInventoryCost,
          value: _money(context, inventoryCost),
          info: l10n.summaryCostInfo,
        ),
      ),
      _SummaryTile(
        icon: Icons.trending_up,
        color: AppColors.info,
        label: l10n.metricSalesValue,
        value: _money(context, expectedRevenue),
        onTap: () => _showInfo(
          context,
          icon: Icons.trending_up,
          color: AppColors.info,
          title: l10n.metricSalesValue,
          value: _money(context, expectedRevenue),
          info: l10n.summaryValueInfo,
        ),
      ),
      _SummaryTile(
        icon: Icons.savings_outlined,
        color: AppColors.success,
        label: l10n.metricNetProfit,
        value: _money(context, netProfit),
        onTap: () => _showInfo(
          context,
          icon: Icons.savings_outlined,
          color: AppColors.success,
          title: l10n.metricNetProfit,
          value: _money(context, netProfit),
          info: l10n.summaryProfitInfo,
        ),
      ),
      _SummaryTile(
        icon: lowStockCount == 0
            ? Icons.check_circle_outline
            : Icons.warning_amber_rounded,
        color: lowStockCount == 0
            ? AppColors.success
            : (hasOut ? colors.error : AppColors.warning),
        label: l10n.dashboardLowStock,
        value: l10n.summaryLowStockValue(lowStockCount),
        onTap: () => _showInfo(
          context,
          icon: Icons.warning_amber_rounded,
          color: hasOut ? colors.error : AppColors.warning,
          title: l10n.dashboardLowStock,
          value: l10n.summaryLowStockValue(lowStockCount),
          info: lowStockCount == 0
              ? l10n.dashboardAllStocked
              : l10n.summaryLowStockInfo,
          details: [
            for (final p in lowStock)
              _detailRow(
                p.name,
                StockLevel.of(p.units) == StockLevel.out
                    ? l10n.outOfStock
                    : l10n.dashboardUnitsLeft(p.units),
                rightColor: StockLevel.of(p.units) == StockLevel.out
                    ? colors.error
                    : null,
              ),
          ],
          actionLabel: l10n.summaryOpenInventory,
          onAction: onOpenInventory,
        ),
      ),
      _SummaryTile(
        icon: Icons.receipt_long_outlined,
        color: colors.primary,
        label: l10n.summaryLastTicket,
        value: lastSale == null
            ? l10n.summaryNoTickets
            : _money(context, lastSale.totalAmount),
        onTap: () => _showInfo(
          context,
          icon: Icons.receipt_long_outlined,
          color: colors.primary,
          title: l10n.dashboardRecentTickets,
          value: lastSale == null
              ? l10n.summaryNoTickets
              : _money(context, lastSale.totalAmount),
          info: l10n.summaryLastTicketInfo,
          details: [
            for (final sale in recentSales.take(5))
              _detailRow(
                '${l10n.ticketTitle(sale.id.toString())} · '
                '${MaterialLocalizations.of(context).formatShortDate(sale.date)}',
                _money(context, sale.totalAmount),
              ),
          ],
          actionLabel: l10n.summaryOpenTickets,
          onAction: onOpenTickets,
        ),
      ),
    ];

    // De dos en dos; el último, si queda solo, a todo el ancho
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final pair = tiles.skip(i).take(2).toList();
      rows.add(
        KeyedSubtree(
          key: i == 0 ? firstTileKey : null,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: pair[0]),
                if (pair.length > 1) ...[
                  const SizedBox(width: 8),
                  Expanded(child: pair[1]),
                ],
              ],
            ),
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }
}

/// Tarjeta compacta: icono a la izquierda; etiqueta y cifra a la derecha.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconBadge(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    height: 1.15,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
