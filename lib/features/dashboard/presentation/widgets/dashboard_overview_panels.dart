import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../inventory/domain/inventory_view.dart';
import '../../../inventory/domain/product.dart';
import '../../../sales/domain/sale.dart';

/// Relleno útil del Inicio en tablet: los últimos tickets y lo que se está
/// acabando, con un toque para ir a la pantalla correspondiente.
class DashboardOverviewPanels extends StatelessWidget {
  const DashboardOverviewPanels({
    super.key,
    required this.recentSales,
    required this.lowStock,
    required this.onOpenTickets,
    required this.onOpenInventory,
  });

  final List<Sale> recentSales;
  final List<Product> lowStock;
  final VoidCallback onOpenTickets;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    Widget panel({
      required String title,
      required IconData icon,
      required VoidCallback onTap,
      required List<Widget> rows,
      required String emptyText,
    }) => AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                emptyText,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            )
          else
            ...rows,
        ],
      ),
    );

    Widget row(String left, String right, {Color? rightColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

    final tickets = panel(
      title: l10n.dashboardRecentTickets,
      icon: Icons.receipt_long_outlined,
      onTap: onOpenTickets,
      emptyText: l10n.dashboardNoTicketsYet,
      rows: [
        for (final sale in recentSales)
          row(
            '${l10n.ticketTitle(sale.id.toString())} · '
            '${MaterialLocalizations.of(context).formatShortDate(sale.date)}',
            context.money(sale.totalAmount),
          ),
      ],
    );
    final stock = panel(
      title: l10n.dashboardLowStock,
      icon: Icons.warning_amber_rounded,
      onTap: onOpenInventory,
      emptyText: l10n.dashboardAllStocked,
      rows: [
        for (final p in lowStock)
          row(
            p.name,
            StockLevel.of(p.units) == StockLevel.out
                ? l10n.outOfStock
                : l10n.dashboardUnitsLeft(p.units),
            rightColor: StockLevel.of(p.units) == StockLevel.out
                ? colors.error
                : null,
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tickets),
        const SizedBox(width: 20),
        Expanded(child: stock),
      ],
    );
  }
}
