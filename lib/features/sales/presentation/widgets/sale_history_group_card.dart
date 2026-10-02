import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/sale.dart';
import '../sale_history_group.dart';

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
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
                  Text(
                    group.key,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: baseColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.ticketCount(group.sales.length.toString()),
                    style: TextStyle(
                      fontSize: 13,
                      color: baseColor.withValues(alpha: 0.8),
                    ),
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
                '${group.total.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: baseColor,
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
                style: TextStyle(color: baseColor, fontWeight: FontWeight.bold),
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

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildSaleItem(BuildContext context, SaleItem item) {
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
                if (item.historicalPrice < item.originalPrice)
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
          Text(
            '${(item.quantity * item.historicalPrice).toStringAsFixed(2)} €',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
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
            '${(packItem.quantity * packItem.historicalPrice).toStringAsFixed(2)} €',
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: headerColor,
            foregroundColor: headerTextColor,
            child: const Icon(Icons.receipt_long),
          ),
          title: Text(
            context.l10n.ticketTitle(sale.id.toString()),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(sale.date),
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ],
          ),
          trailing: Text(
            '${sale.totalAmount.toStringAsFixed(2)} €',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),
                  ...sale.items.map((item) => _buildSaleItem(context, item)),
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
