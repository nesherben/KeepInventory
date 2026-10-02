import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/services/app_preferences.dart';

class FullScreenChartScreen extends StatefulWidget {
  final Map<String, double> dailySales;
  final Map<String, double> dailyNetProfits;

  const FullScreenChartScreen({
    super.key,
    required this.dailySales,
    required this.dailyNetProfits,
  });

  @override
  State<FullScreenChartScreen> createState() => _FullScreenChartScreenState();
}

class _FullScreenChartScreenState extends State<FullScreenChartScreen> {
  late bool _privacyActive;

  @override
  void initState() {
    super.initState();
    _privacyActive = AppPreferences.privacyModeEnabled.value;
    AppPreferences.privacyModeEnabled.addListener(_onPrivacyModeChanged);
  }

  @override
  void dispose() {
    AppPreferences.privacyModeEnabled.removeListener(_onPrivacyModeChanged);
    super.dispose();
  }

  void _onPrivacyModeChanged() {
    if (mounted) {
      setState(() {
        _privacyActive = AppPreferences.privacyModeEnabled.value;
      });
    }
  }

  void _togglePrivacyMode() {
    unawaited(AppPreferences.setPrivacyModeEnabled(!_privacyActive));
  }

  String _formatCurrency(double amount) {
    if (_privacyActive) return '•••••• €';
    return '${amount.toStringAsFixed(2)} €';
  }

  Widget _buildHeaderAndLegend(
    BuildContext context,
    double totalSales,
    double totalNet,
    Color cardBackground,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTotal(
                context,
                context.l10n.chartTotalRevenue,
                _formatCurrency(totalSales),
                Theme.of(context).colorScheme.primary,
              ),
              Container(
                height: 30,
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              _buildTotal(
                context,
                context.l10n.chartTotalNet,
                _formatCurrency(totalNet),
                Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              _buildLegendItem(
                context,
                Theme.of(context).colorScheme.primary,
                context.l10n.chartDays,
                cardBackground,
              ),
              _buildLegendItem(
                context,
                Theme.of(context).colorScheme.secondary,
                context.l10n.chartFairs,
                cardBackground,
              ),
              _buildLegendItem(
                context,
                Theme.of(context).colorScheme.tertiary,
                context.l10n.chartNetProfit,
                cardBackground,
                isCircle: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotal(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    Color color,
    String label,
    Color cardBackground, {
    bool isCircle = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCircle ? 10 : 12,
          height: isCircle ? 10 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(3),
            border: isCircle
                ? Border.all(color: cardBackground, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildChartContent(
    BuildContext context,
    List<String> sortedKeys,
    double maxValue,
    Color cardBackground,
  ) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sortedKeys
            .map(
              (key) => _buildChartBar(context, key, maxValue, cardBackground),
            )
            .toList(),
      ),
    );
  }

  Widget _buildChartBar(
    BuildContext context,
    String key,
    double maxValue,
    Color cardBackground,
  ) {
    final revenue = widget.dailySales[key] ?? 0.0;
    final net = widget.dailyNetProfits[key] ?? 0.0;
    final revenueFactor = maxValue == 0 ? 0.0 : revenue / maxValue;
    final netFactor = maxValue == 0 ? 0.0 : net / maxValue;

    final parts = key.split('-');
    final shortLabel = parts.length == 3
        ? '${parts[2]}/${parts[1]}'
        : (key.length > 6 ? '${key.substring(0, 5)}..' : key);
    final isFair = parts.length != 3;
    final barColor = isFair
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _privacyActive ? '••€' : '${revenue.toStringAsFixed(0)}€',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barHeight = constraints.maxHeight * revenueFactor;
                final dotBottom = constraints.maxHeight * netFactor;

                return Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: barHeight,
                        width: 18,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: dotBottom > 0 ? dotBottom - 6 : 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBackground, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow
                                  .withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shortLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<String> sortedKeys) {
    return ListView.separated(
      itemCount: sortedKeys.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final key = sortedKeys[sortedKeys.length - 1 - index];
        final revenue = widget.dailySales[key] ?? 0.0;
        final net = widget.dailyNetProfits[key] ?? 0.0;

        final parts = key.split('-');
        final isDate = parts.length == 3;
        final formattedTitle = isDate
            ? context.l10n.chartDayTitle('${parts[2]}/${parts[1]}/${parts[0]}')
            : context.l10n.chartFairTitle(key);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                (isDate
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary)
                    .withValues(alpha: 0.15),
            child: Icon(
              isDate ? Icons.calendar_month : Icons.store,
              color: isDate
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ),
          title: Text(
            formattedTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text(
            context.l10n.chartRevenue(_formatCurrency(revenue)),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            context.l10n.chartNet(_formatCurrency(net)),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= 600;

    final cardBgColor = Theme.of(context).cardColor;

    double maxVal = 0.0;
    for (var val in widget.dailySales.values) {
      if (val > maxVal) maxVal = val;
    }
    for (var val in widget.dailyNetProfits.values) {
      if (val > maxVal) maxVal = val;
    }

    final double totalSales = widget.dailySales.values.fold(
      0.0,
      (sum, v) => sum + v,
    );
    final double totalNet = widget.dailyNetProfits.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    final Set<String> allKeys = {
      ...widget.dailySales.keys,
      ...widget.dailyNetProfits.keys,
    };
    final List<String> sortedKeys = allKeys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.chartDetailsTitle),
        actions: [
          IconButton(
            icon: Icon(
              _privacyActive ? Icons.visibility_off : Icons.visibility,
              color: _privacyActive
                  ? Theme.of(context).colorScheme.secondary
                  : null,
            ),
            onPressed: _togglePrivacyMode,
            tooltip: _privacyActive
                ? context.l10n.privacyOffShort
                : context.l10n.privacyOnShort,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sortedKeys.isEmpty
          ? Center(
              child: Text(
                context.l10n.chartEmpty,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : isWideScreen
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    color: Theme.of(context).cardColor,
                    child: _buildListView(context, sortedKeys),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeaderAndLegend(
                        context,
                        totalSales,
                        totalNet,
                        cardBgColor,
                      ),
                      Expanded(
                        child: _buildChartContent(
                          context,
                          sortedKeys,
                          maxVal,
                          cardBgColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildHeaderAndLegend(
                  context,
                  totalSales,
                  totalNet,
                  cardBgColor,
                ),
                Expanded(
                  flex: 3,
                  child: _buildChartContent(
                    context,
                    sortedKeys,
                    maxVal,
                    cardBgColor,
                  ),
                ),
                Expanded(flex: 2, child: _buildListView(context, sortedKeys)),
              ],
            ),
    );
  }
}
