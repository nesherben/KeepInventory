import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inventory/domain/inventory_view.dart';
import '../../../sales/domain/sale.dart';
import '../../../sales/presentation/widgets/payment_method_widgets.dart';
import '../../domain/dashboard_today_summary.dart';
import 'dashboard_summary_sheets.dart';

/// Resumen del Inicio en móvil: la sección "Hoy" (ventas y tickets) y la de
/// "Almacén y balance", con tarjetas compactas de dos en dos. Al tocar una
/// sale una ficha con qué significa la cifra y, a veces, su detalle.
class DashboardSummaryGrid extends StatelessWidget {
  const DashboardSummaryGrid({
    super.key,
    required this.today,
    required this.inventoryCost,
    required this.expectedRevenue,
    required this.netProfit,
    required this.onOpenTickets,
    required this.onOpenInventory,
    this.hideAmounts = false,
    this.firstTileKey,
  });

  final DashboardTodaySummary today;
  final double inventoryCost;
  final double expectedRevenue;

  /// Beneficio acumulado de siempre (no es el de hoy).
  final double netProfit;
  final VoidCallback onOpenTickets;
  final VoidCallback onOpenInventory;

  /// Modo privacidad: los importes y el nº de tickets se ocultan.
  final bool hideAmounts;

  /// Clave de todo el resumen (la usa la guía de la pantalla).
  final Key? firstTileKey;

  String _money(BuildContext context, double value) =>
      hideAmounts ? '•••••• €' : context.money(value);

  String _time(BuildContext context, DateTime date) => MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true);

  Widget _row(List<Widget> pair, {Key? key}) => KeyedSubtree(
    key: key,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: pair[0]),
          const SizedBox(width: 8),
          Expanded(child: pair[1]),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final last = today.lastTicket;
    final restockCount = today.restock.length;
    final hasOut = today.outCount > 0;
    final neutral = colors.onSurfaceVariant;
    final stockColor = restockCount == 0
        ? neutral
        : (hasOut ? colors.error : AppColors.warning);
    final stockIcon = restockCount == 0
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;
    final salesValue = _money(context, today.total);
    final ticketsValue = hideAmounts ? '••' : '${today.ticketCount}';

    final salesTile = _SummaryTile(
      icon: Icons.point_of_sale,
      color: colors.primary,
      label: l10n.dashSalesToday,
      value: salesValue,
      subtitle: today.ticketCount == 0 ? l10n.dashNoSalesToday : null,
      onTap: () => showSummarySheet(
        context,
        icon: Icons.point_of_sale,
        color: colors.primary,
        title: l10n.dashSalesToday,
        value: salesValue,
        info: l10n.dashSalesTodayInfo,
        details: [
          SectionLabel(l10n.dashByMethodToday),
          for (final method in PaymentMethod.values)
            // "Sin especificar" solo si hoy hay algo con ese método
            if (method != PaymentMethod.unspecified ||
                (today.byMethod[method] ?? 0).abs() >= 0.005)
              summaryDetailRow(
                method.label(context),
                _money(context, today.byMethod[method] ?? 0),
                leading: Icon(
                  method.icon,
                  size: 20,
                  color: method.colorOf(context),
                ),
              ),
        ],
        actionLabel: l10n.summaryOpenTickets,
        onAction: onOpenTickets,
      ),
    );

    final ticketsTile = _SummaryTile(
      icon: Icons.receipt_long,
      color: colors.primary,
      label: l10n.dashTicketsToday,
      value: ticketsValue,
      subtitle: last == null
          ? null
          : l10n.dashLastTicketAt(
              _time(context, last.date),
              _money(context, last.amount),
            ),
      onTap: () => showSummarySheet(
        context,
        icon: Icons.receipt_long,
        color: colors.primary,
        title: l10n.dashTicketsToday,
        value: ticketsValue,
        info: today.ticketCount == 0
            ? l10n.dashNoTicketsToday
            : l10n.dashTicketsTodayInfo,
        details: [
          for (final t in today.latestTickets)
            summaryDetailRow(_time(context, t.date), _money(context, t.amount)),
        ],
        actionLabel: l10n.summaryOpenTickets,
        onAction: onOpenTickets,
      ),
    );

    final costValue = _money(context, inventoryCost);
    final costTile = _SummaryTile(
      icon: Icons.inventory_2_outlined,
      color: neutral,
      label: l10n.dashInventoryCost,
      value: costValue,
      onTap: () => showSummarySheet(
        context,
        icon: Icons.inventory_2_outlined,
        color: neutral,
        title: l10n.dashInventoryCost,
        value: costValue,
        info: l10n.summaryCostInfo,
      ),
    );

    final worthValue = _money(context, expectedRevenue);
    final worthTile = _SummaryTile(
      icon: Icons.trending_up,
      color: neutral,
      label: l10n.dashSalesValue,
      value: worthValue,
      onTap: () => showSummarySheet(
        context,
        icon: Icons.trending_up,
        color: neutral,
        title: l10n.dashSalesValue,
        value: worthValue,
        info: l10n.summaryValueInfo,
      ),
    );

    final profitValue = _money(context, netProfit);
    final profitTile = _SummaryTile(
      icon: Icons.savings_outlined,
      color: AppColors.success,
      label: l10n.dashNetProfit,
      value: profitValue,
      onTap: () => showSummarySheet(
        context,
        icon: Icons.savings_outlined,
        color: AppColors.success,
        title: l10n.dashNetProfit,
        value: profitValue,
        info: l10n.dashNetProfitInfo,
      ),
    );

    final restockTile = _SummaryTile(
      icon: stockIcon,
      color: stockColor,
      label: l10n.dashRestock,
      value: '$restockCount',
      subtitle: restockCount == 0
          ? l10n.dashAllInStock
          : (hasOut ? l10n.dashOutCount(today.outCount) : null),
      onTap: () => showSummarySheet(
        context,
        icon: stockIcon,
        color: stockColor,
        title: l10n.dashRestock,
        value: '$restockCount',
        info: restockCount == 0
            ? l10n.dashboardAllStocked
            : l10n.summaryLowStockInfo,
        details: [
          for (final p in today.restock)
            summaryDetailRow(
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
    );

    return KeyedSubtree(
      key: firstTileKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.dashTodaySection),
          _row([salesTile, ticketsTile]),
          const SizedBox(height: AppSpacing.md),
          SectionLabel(l10n.dashStockSection),
          _row([costTile, worthTile]),
          const SizedBox(height: 8),
          _row([profitTile, restockTile]),
        ],
      ),
    );
  }
}

/// Tarjeta compacta: icono a la izquierda; etiqueta, cifra y subtítulo opcional.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
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
