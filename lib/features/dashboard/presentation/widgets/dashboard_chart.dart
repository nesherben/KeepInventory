import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FullScreenChartScreen extends StatefulWidget {
  final Map<String, double> dailySales;
  final Map<String, double> dailyNetProfits;
  final bool isPrivacyModeEnabled;

  const FullScreenChartScreen({
    super.key,
    required this.dailySales,
    required this.dailyNetProfits,
    required this.isPrivacyModeEnabled,
  });

  @override
  State<FullScreenChartScreen> createState() => _FullScreenChartScreenState();
}

class _FullScreenChartScreenState extends State<FullScreenChartScreen> {
  late bool _privacyActive;

  @override
  void initState() {
    super.initState();
    _privacyActive = widget.isPrivacyModeEnabled;
  }

  String _formatCurrency(double amount) {
    if (_privacyActive) return '•••••• €';
    return '${amount.toStringAsFixed(2)} €';
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

    Widget buildChartContent() {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        decoration: BoxDecoration(
          color: cardBgColor,
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
          children: sortedKeys.map((key) {
            final revenue = widget.dailySales[key] ?? 0.0;
            final net = widget.dailyNetProfits[key] ?? 0.0;

            final revFactor = maxVal == 0 ? 0.0 : revenue / maxVal;
            final netFactor = maxVal == 0 ? 0.0 : net / maxVal;

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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barHeight = constraints.maxHeight * revFactor;
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
                                  border: Border.all(
                                    color: cardBgColor,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .shadow
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
          }).toList(),
        ),
      );
    }

    Widget buildHeaderAndLegend() {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
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
                Column(
                  children: [
                    Text(
                      'TOTAL INGRESOS',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalSales),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Column(
                  children: [
                    Text(
                      'TOTAL NETO',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalNet),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Días sueltos',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ferias',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBgColor, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Beneficio Neto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildListView() {
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
              ? 'Día: ${parts[2]}/${parts[1]}/${parts[0]}'
              : '🎪 Feria: $key';

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
              'Ingresos: ${_formatCurrency(revenue)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              'Neto: ${_formatCurrency(net)}',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Detallado'),
        actions: [
          IconButton(
            icon: Icon(
              _privacyActive ? Icons.visibility_off : Icons.visibility,
              color: _privacyActive
                  ? Theme.of(context).colorScheme.secondary
                  : null,
            ),
            onPressed: () {
              setState(() {
                _privacyActive = !_privacyActive;
              });
            },
            tooltip: _privacyActive
                ? 'Desactivar privacidad'
                : 'Activar privacidad',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sortedKeys.isEmpty
          ? Center(
              child: Text(
                'Aún no hay ventas para mostrar.',
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
                    child: buildListView(),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    children: [
                      buildHeaderAndLegend(),
                      Expanded(child: buildChartContent()),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                buildHeaderAndLegend(),
                Expanded(flex: 3, child: buildChartContent()),
                Expanded(flex: 2, child: buildListView()),
              ],
            ),
    );
  }
}
