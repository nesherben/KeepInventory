import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../inventory/domain/inventory_view.dart';
import '../../../inventory/domain/product.dart';
import '../../../sales/domain/sale.dart';

/// Relleno útil del Inicio: los últimos tickets y lo que se está acabando, con
/// un toque para ir a la pantalla correspondiente. En tablet van en dos
/// columnas; en móvil ([compact]) apilados, con el stock primero y pocas filas.
class DashboardOverviewPanels extends StatelessWidget {
  const DashboardOverviewPanels({
    super.key,
    required this.recentSales,
    required this.lowStock,
    required this.onOpenTickets,
    required this.onOpenInventory,
    this.hideAmounts = false,
    this.compact = false,
  });

  final List<Sale> recentSales;
  final List<Product> lowStock;
  final VoidCallback onOpenTickets;
  final VoidCallback onOpenInventory;

  /// Modo privacidad: los importes se ocultan.
  final bool hideAmounts;

  /// Móvil: apilados y con menos filas.
  final bool compact;

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
        for (final sale in recentSales.take(compact ? 3 : recentSales.length))
          row(
            '${l10n.ticketTitle(sale.id.toString())} · '
            '${MaterialLocalizations.of(context).formatShortDate(sale.date)}',
            hideAmounts ? '•••••• €' : context.money(sale.totalAmount),
          ),
      ],
    );
    final stock = panel(
      title: l10n.dashboardLowStock,
      icon: Icons.warning_amber_rounded,
      onTap: onOpenInventory,
      emptyText: l10n.dashboardAllStocked,
      rows: [
        for (final p in lowStock.take(compact ? 3 : lowStock.length))
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

    // Móvil: el stock que se acaba es lo accionable, va primero
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [stock, const SizedBox(height: 12), tickets],
      );
    }

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
