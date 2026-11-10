import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Intl, NumberFormat;
import 'package:keepinventory/core/utils/app_numbers.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../sales/domain/payment_method.dart';
import '../../../sales/presentation/widgets/payment_method_widgets.dart';

part 'dashboard_chart_painters.dart';

/// Pantalla de balance por ferias y días.
///
/// Estructura (de arriba abajo): filtro → cifras clave → gráfico de barras
/// apiladas por método de pago con marca de beneficio neto → detalle de la
/// barra seleccionada → historial completo (también sirve de vista tabla).
class FullScreenChartScreen extends StatefulWidget {
  final Map<String, double> dailySales;
  final Map<String, double> dailyNetProfits;
  final Map<String, Map<PaymentMethod, double>> revenueByMethodPerGroup;

  const FullScreenChartScreen({
    super.key,
    required this.dailySales,
    required this.dailyNetProfits,
    this.revenueByMethodPerGroup = const {},
  });

  @override
  State<FullScreenChartScreen> createState() => _FullScreenChartScreenState();
}

enum _GroupFilter { all, fairs, days }

/// Un día suelto o una feria, con sus importes ya calculados.
class _Group {
  _Group({
    required this.key,
    required this.isFair,
    required this.revenue,
    required this.net,
    required this.methods,
  });

  final String key;
  final bool isFair;
  final double revenue;
  final double net;
  final Map<PaymentMethod, double> methods;

  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  double get margin => revenue > 0 ? net / revenue * 100 : 0;

  /// Etiqueta corta para el eje: "07/11" o el nombre de la feria.
  String get shortLabel {
    if (isFair) return key;
    final p = key.split('-');
    return '${p[2]}/${p[1]}';
  }

  String title(BuildContext context) {
    if (isFair) return context.l10n.chartFairTitle(key);
    final p = key.split('-');
    return context.l10n.chartDayTitle('${p[2]}/${p[1]}/${p[0]}');
  }
}

class _FullScreenChartScreenState extends State<FullScreenChartScreen> {
  static const double _columnWidth = 60;
  static const double _plotHeight = 200;
  static const double _labelHeight = 34;

  late bool _privacyActive;
  late final List<_Group> _groups;
  final _chartScroll = ScrollController();
  _GroupFilter _filter = _GroupFilter.all;
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _privacyActive = AppPreferences.privacyModeEnabled.value;
    AppPreferences.privacyModeEnabled.addListener(_onPrivacyModeChanged);
    _groups = _buildGroups();
    _selectedKey = _groups.isEmpty ? null : _groups.last.key;
    _scrollChartToEnd();
  }

  @override
  void dispose() {
    AppPreferences.privacyModeEnabled.removeListener(_onPrivacyModeChanged);
    _chartScroll.dispose();
    super.dispose();
  }

  void _onPrivacyModeChanged() {
    if (mounted) {
      setState(() => _privacyActive = AppPreferences.privacyModeEnabled.value);
    }
  }

  void _togglePrivacyMode() {
    unawaited(AppPreferences.setPrivacyModeEnabled(!_privacyActive));
  }

  /// Une los tres mapas en grupos, en orden cronológico (el de dailySales).
  List<_Group> _buildGroups() {
    final keys = <String>{
      ...widget.dailySales.keys,
      ...widget.dailyNetProfits.keys,
    };
    return [
      for (final key in keys)
        _Group(
          key: key,
          isFair: !_Group._datePattern.hasMatch(key),
          revenue: widget.dailySales[key] ?? 0,
          net: widget.dailyNetProfits[key] ?? 0,
          methods: widget.revenueByMethodPerGroup[key] ?? const {},
        ),
    ];
  }

  List<_Group> get _visibleGroups => switch (_filter) {
    _GroupFilter.all => _groups,
    _GroupFilter.fairs => _groups.where((g) => g.isFair).toList(),
    _GroupFilter.days => _groups.where((g) => !g.isFair).toList(),
  };

  void _scrollChartToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartScroll.hasClients) {
        _chartScroll.jumpTo(_chartScroll.position.maxScrollExtent);
      }
    });
  }

  void _setFilter(_GroupFilter filter) {
    setState(() {
      _filter = filter;
      final visible = _visibleGroups;
      if (!visible.any((g) => g.key == _selectedKey)) {
        _selectedKey = visible.isEmpty ? null : visible.last.key;
      }
    });
    _scrollChartToEnd();
  }

  /// Selecciona un grupo y centra su barra en el gráfico.
  void _select(String key, {bool scrollChart = false}) {
    setState(() => _selectedKey = key);
    if (!scrollChart || !_chartScroll.hasClients) return;
    final index = _visibleGroups.indexWhere((g) => g.key == key);
    if (index < 0) return;
    final viewport = _chartScroll.position.viewportDimension;
    final target = (index * _columnWidth - (viewport - _columnWidth) / 2).clamp(
      0.0,
      _chartScroll.position.maxScrollExtent,
    );
    _chartScroll.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatCurrency(double amount) {
    if (_privacyActive) return '•••••• €';
    return context.money(amount);
  }

  String _formatPercent(double value) => '${value.toStringAsFixed(1)} %';

  /// Métodos que aparecen en el gráfico (orden fijo; "sin especificar" solo
  /// si alguna barra visible lo tiene).
  List<PaymentMethod> _methodsInUse(List<_Group> groups) => [
    ...PaymentMethod.selectable,
    if (groups.any((g) => (g.methods[PaymentMethod.unspecified] ?? 0) > 0.005))
      PaymentMethod.unspecified,
  ];

  // ---------------------------------------------------------------------------
  // Cabecera: filtro + cifras clave
  // ---------------------------------------------------------------------------

  Widget _buildFilter() {
    return SegmentedButton<_GroupFilter>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: _GroupFilter.all,
          label: Text(context.l10n.chartFilterAll),
        ),
        ButtonSegment(
          value: _GroupFilter.fairs,
          label: Text(context.l10n.chartFairs),
        ),
        ButtonSegment(
          value: _GroupFilter.days,
          label: Text(context.l10n.chartDays),
        ),
      ],
      selected: {_filter},
      onSelectionChanged: (s) => _setFilter(s.first),
    );
  }

  Widget _buildSummary(List<_Group> groups) {
    final revenue = groups.fold<double>(0, (s, g) => s + g.revenue);
    final net = groups.fold<double>(0, (s, g) => s + g.net);
    final margin = revenue > 0 ? net / revenue * 100 : 0.0;
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            context.l10n.chartTotalRevenue,
            _formatCurrency(revenue),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            context.l10n.chartTotalNet,
            _formatCurrency(net),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            context.l10n.chartMargin,
            revenue > 0 ? _formatPercent(margin) : '—',
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value) =>
      StatTile(label: label, value: value);

  // ---------------------------------------------------------------------------
  // Gráfico
  // ---------------------------------------------------------------------------

  Widget _buildChartCard(List<_Group> groups) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: groups.isEmpty
          ? SizedBox(
              height: _plotHeight,
              child: Center(
                child: Text(
                  context.l10n.chartNoDataForFilter,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(groups),
                const SizedBox(height: 16),
                _buildPlot(groups),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    context.l10n.chartTapHint,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Leyenda: color = método (siempre con nombre), marca = beneficio neto.
  Widget _buildLegend(List<_Group> groups) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final textStyle = TextStyle(fontSize: 12, color: ink);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final method in _methodsInUse(groups))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: method.colorOf(context),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(method.label(context), style: textStyle),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 3, color: ink),
            const SizedBox(width: 6),
            Text(context.l10n.chartNetProfit, style: textStyle),
          ],
        ),
      ],
    );
  }

  Widget _buildPlot(List<_Group> groups) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Escala única en € (ingresos y beneficio comparten unidad → un solo eje)
    var maxValue = groups.fold<double>(
      0,
      (m, g) => math.max(m, math.max(g.revenue, g.net)),
    );
    final minValue = groups.fold<double>(0, (m, g) => math.min(m, g.net));
    final ticks = _niceTicks(minValue, maxValue <= 0 ? 1 : maxValue);
    final scale = _Scale(ticks.first, ticks.last, _plotHeight);
    maxValue = ticks.last;

    final methods = _methodsInUse(groups);
    final methodColors = {for (final m in methods) m: m.colorOf(context)};
    final surface = theme.cardColor;

    return SizedBox(
      height: _plotHeight + _labelHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eje Y (oculto en modo privacidad)
          SizedBox(
            width: 44,
            height: _plotHeight,
            child: CustomPaint(
              painter: _AxisLabelsPainter(
                ticks: _privacyActive ? const [] : ticks,
                scale: scale,
                color: colors.onSurfaceVariant,
                locale: Localizations.localeOf(context).toString(),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _plotHeight,
                  child: CustomPaint(
                    painter: _GridPainter(
                      ticks: ticks,
                      scale: scale,
                      gridColor: colors.outlineVariant.withValues(alpha: 0.5),
                      baselineColor: colors.outline,
                    ),
                  ),
                ),
                ListView.builder(
                  controller: _chartScroll,
                  scrollDirection: Axis.horizontal,
                  itemCount: groups.length,
                  itemExtent: _columnWidth,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _buildColumn(
                      group,
                      scale: scale,
                      methods: methods,
                      methodColors: methodColors,
                      surface: surface,
                      ink: colors.onSurface,
                      selectedFill: colors.primary.withValues(alpha: 0.08),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    _Group group, {
    required _Scale scale,
    required List<PaymentMethod> methods,
    required Map<PaymentMethod, Color> methodColors,
    required Color surface,
    required Color ink,
    required Color selectedFill,
  }) {
    final selected = group.key == _selectedKey;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${group.title(context)}: ${_formatCurrency(group.revenue)}, '
          '${context.l10n.chartNet(_formatCurrency(group.net))}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(group.key),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? selectedFill : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              SizedBox(
                height: _plotHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BarPainter(
                    group: group,
                    scale: scale,
                    methods: methods,
                    methodColors: methodColors,
                    surface: selected
                        ? Color.alphaBlend(selectedFill, surface)
                        : surface,
                    ink: ink,
                  ),
                ),
              ),
              SizedBox(
                height: _labelHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    group.shortLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.15,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 4–5 marcas "redondas" (1, 2, 5 × 10ⁿ) que cubren [min, max].
  static List<double> _niceTicks(double min, double max) {
    final range = max - min;
    final rawStep = range / 4;
    final magnitude = math
        .pow(10, (math.log(rawStep) / math.ln10).floor())
        .toDouble();
    final normalized = rawStep / magnitude;
    final step =
        (normalized <= 1
            ? 1
            : normalized <= 2
            ? 2
            : normalized <= 5
            ? 5
            : 10) *
        magnitude;
    final start = (min / step).floor() * step;
    final end = (max / step).ceil() * step;
    return [for (var v = start; v <= end + step / 2; v += step) v];
  }

  // ---------------------------------------------------------------------------
  // Detalle de la barra seleccionada
  // ---------------------------------------------------------------------------

  Widget _buildDetailCard(_Group group) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final methods = [
      for (final m in PaymentMethod.values)
        if ((group.methods[m] ?? 0).abs() > 0.005) m,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                group.isFair ? Icons.store : Icons.calendar_month,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailValue(
                  context.l10n.chartTotalRevenue,
                  _formatCurrency(group.revenue),
                ),
              ),
              Expanded(
                child: _buildDetailValue(
                  context.l10n.chartTotalNet,
                  _formatCurrency(group.net),
                ),
              ),
              Expanded(
                child: _buildDetailValue(
                  context.l10n.chartMargin,
                  group.revenue > 0 ? _formatPercent(group.margin) : '—',
                ),
              ),
            ],
          ),
          if (methods.isNotEmpty) ...[
            const Divider(height: 28),
            Text(
              context.l10n.revenueByPaymentMethod,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in methods) _buildMethodRow(group, m),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailValue(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Fila: icono · nombre · importe · % con barra de proporción.
  Widget _buildMethodRow(_Group group, PaymentMethod method) {
    final colors = Theme.of(context).colorScheme;
    final amount = group.methods[method] ?? 0;
    final share = group.revenue > 0 ? amount / group.revenue : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Icon(method.icon, size: 18, color: method.colorOf(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  method.label(context),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _formatCurrency(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  _formatPercent(share * 100),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 6,
              color: method.colorOf(context),
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Historial (vista tabla)
  // ---------------------------------------------------------------------------

  Widget _buildHistoryHeader() {
    return SectionLabel(
      context.l10n.chartHistory,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    );
  }

  Widget _buildHistoryRow(_Group group) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: 14,
      selected: group.key == _selectedKey,
      onTap: () => _select(group.key, scrollChart: true),
      child: Row(
        children: [
          Icon(
            group.isFair ? Icons.store : Icons.calendar_month,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                _buildShareBar(group),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(group.revenue),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.chartNet(_formatCurrency(group.net)),
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Barra fina 100% con el reparto por método (separadores de 2px).
  Widget _buildShareBar(_Group group) {
    final parts = [
      for (final m in PaymentMethod.values)
        if ((group.methods[m] ?? 0) > 0.005) (m, group.methods[m]!),
    ];
    if (parts.isEmpty || group.revenue <= 0) return const SizedBox(height: 6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: math.max(1, (parts[i].$2 / group.revenue * 1000).round()),
                child: ColoredBox(color: parts[i].$1.colorOf(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 700;
    final visible = _visibleGroups;
    final selected = visible.where((g) => g.key == _selectedKey).firstOrNull;
    final history = visible.reversed.toList(); // más reciente primero

    final overview = <Widget>[
      _buildFilter(),
      const SizedBox(height: 16),
      _buildSummary(visible),
      const SizedBox(height: 16),
      _buildChartCard(visible),
      if (selected != null) ...[
        const SizedBox(height: 16),
        _buildDetailCard(selected),
      ],
    ];
    final historyItems = <Widget>[
      if (history.isNotEmpty) _buildHistoryHeader(),
      for (final g in history) _buildHistoryRow(g),
    ];

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
      body: _groups.isEmpty
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: overview,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: historyItems,
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...overview,
                const SizedBox(height: 16),
                ...historyItems,
              ],
            ),
    );
  }
}
