import 'package:flutter/material.dart';
import 'package:keepinventory/core/utils/app_numbers.dart';

import '../../../../core/shared_widgets/app_ui.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/sale.dart';
import '../sale_history_group.dart';
import 'payment_method_widgets.dart';

class SaleHistoryGroupCard extends StatelessWidget {
  const SaleHistoryGroupCard({
    super.key,
    required this.group,
    required this.onAssignFair,
    required this.onRefund,
  });

  final SaleHistoryGroup group;
  final void Function(String datePrefix, String currentFairName) onAssignFair;
  final ValueChanged<Sale> onRefund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = group.isFair
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;
    final headerColor = baseColor.withValues(alpha: 0.12);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: theme.colorScheme.surface,
        collapsedBackgroundColor: headerColor,
        shape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        group.isFair
                            ? Icons.storefront_outlined
                            : Icons.calendar_today_outlined,
                        size: 20,
                        color: baseColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.ticketCount(group.sales.length),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Recuento por método para cuadrar la caja de la feria/día
                  PaymentMethodTotals(
                    totals: PaymentMethod.totalsOf(group.sales),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.money(group.total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: Icon(
                group.isFair ? Icons.edit : Icons.add_circle,
                size: 16,
                color: baseColor,
              ),
              label: Text(
                group.isFair
                    ? context.l10n.changeFair
                    : context.l10n.groupIntoFair,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(color: baseColor.withValues(alpha: 0.5)),
              onPressed: () => onAssignFair(group.datePrefix, group.fairName),
            ),
          ),
        ),
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.2,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: group.sales
                  .map(
                    (sale) => _SaleTicketCard(
                      sale: sale,
                      headerColor: headerColor,
                      headerTextColor: baseColor,
                      onRefund: () => onRefund(sale),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleTicketCard extends StatelessWidget {
  const _SaleTicketCard({
    required this.sale,
    required this.headerColor,
    required this.headerTextColor,
    required this.onRefund,
  });

  final Sale sale;
  final Color headerColor;
  final Color headerTextColor;
  final VoidCallback onRefund;

  /// Devoluciones parciales ya hechas: importe, cuándo y qué se devolvió.
  List<Widget> _buildRefunds(BuildContext context) {
    if (sale.refunds.isEmpty) return const [];
    final colors = Theme.of(context).colorScheme;
    String when(DateTime d) {
      final sameDay =
          d.year == sale.date.year &&
          d.month == sale.date.month &&
          d.day == sale.date.day;
      final day =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      return sameDay ? _formatDateTime(d) : '$day ${_formatDateTime(d)}';
    }

    return [
      const Divider(height: 16),
      for (final refund in sale.refunds)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.undo, size: 16, color: colors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.ticketRefundLine(
                        context.amount(refund.amount),
                        when(refund.date),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.error,
                      ),
                    ),
                    Text(
                      refund.summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildSaleItem(BuildContext context, SaleItem item) {
    final colors = Theme.of(context).colorScheme;
    final originalTotal = item.originalPrice * item.quantity;
    final discountedTotal = item.historicalPrice * item.quantity;
    final hasDiscount = originalTotal > discountedTotal + 0.005;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.quantity}x',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? context.l10n.unknown,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (hasDiscount)
                  Text(
                    context.l10n.discountApplied,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount)
                Text(
                  context.money(originalTotal),
                  style: TextStyle(
                    color: colors.error,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 12,
                  ),
                ),
              Text(
                context.money(discountedTotal),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Líneas del ticket: primero cada combo (cabecera + sus productos) y
  /// después los productos sueltos.
  List<Widget> _buildItems(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final widgets = <Widget>[];
    final grouped = <SaleItem>{};
    for (final combo in sale.combos) {
      final lines = sale.items.where((i) => i.saleComboId == combo.id).toList();
      if (lines.isEmpty) continue;
      grouped.addAll(lines);
      final total = lines.fold<double>(
        0,
        (t, i) => t + i.historicalPrice * i.quantity,
      );
      final full = lines.fold<double>(
        0,
        (t, i) => t + i.refundUnitPrice * i.quantity,
      );
      final title = context.l10n.comboCartTitle(combo.name);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.extension, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  combo.quantity > 1
                      ? '$title ${context.l10n.comboCount(combo.quantity)}'
                      : title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                context.money(total),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
      if (full - total > 0.005) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              context.l10n.comboSaving(context.amount(full - total)),
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ),
        );
      }
      for (final line in lines) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: _buildSaleItem(context, line),
          ),
        );
      }
    }
    for (final item in sale.items) {
      if (!grouped.contains(item)) widgets.add(_buildSaleItem(context, item));
    }
    return widgets;
  }

  Widget _buildPackItem(BuildContext context, SalePackItem packItem) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${packItem.quantity}x',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packItem.packName ?? context.l10n.unknownPackDeleted,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PACK',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            context.money(packItem.quantity * packItem.historicalPrice),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: IconBadge(Icons.receipt_long, color: headerTextColor),
          title: Text(
            context.l10n.ticketTitle(sale.id.toString()),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(sale.date),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                PaymentMethodBadge(method: sale.paymentMethod),
              ],
            ),
          ),
          trailing: Text(
            context.money(sale.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),
                  ..._buildItems(context),
                  ..._buildRefunds(context),
                  if (sale.packItems.isNotEmpty && sale.items.isNotEmpty)
                    const SizedBox(height: 8),
                  ...sale.packItems.map(
                    (packItem) => _buildPackItem(context, packItem),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                      ),
                      icon: const Icon(Icons.undo, size: 18),
                      label: Text(context.l10n.refund),
                      onPressed: onRefund,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
