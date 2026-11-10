part of 'dashboard_chart.dart';

/// Conversión valor (€) → coordenada Y dentro del área de dibujo.
class _Scale {
  const _Scale(this.min, this.max, this.height);

  final double min;
  final double max;
  final double height;

  static const double _topPadding = 8;
  static const double _bottomPadding = 6;

  double y(double value) {
    final range = max - min;
    if (range <= 0) return height;
    final usable = height - _topPadding - _bottomPadding;
    return height - _bottomPadding - (value - min) / range * usable;
  }
}

/// Rejilla horizontal discreta + línea base en 0.
class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.ticks,
    required this.scale,
    required this.gridColor,
    required this.baselineColor,
  });

  final List<double> ticks;
  final _Scale scale;
  final Color gridColor;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final t in ticks) {
      final y = scale.y(t);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final base = Paint()
      ..color = baselineColor
      ..strokeWidth = 1;
    final y0 = scale.y(0);
    canvas.drawLine(Offset(0, y0), Offset(size.width, y0), base);
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.ticks != ticks ||
      old.gridColor != gridColor ||
      old.baselineColor != baselineColor;
}

/// Etiquetas del eje Y alineadas a la derecha ("1,5k €", "200 €").
class _AxisLabelsPainter extends CustomPainter {
  _AxisLabelsPainter({
    required this.ticks,
    required this.scale,
    required this.color,
    required this.locale,
  });

  final List<double> ticks;
  final _Scale scale;
  final Color color;
  final String locale;

  /// "1,5k €" (es) / "1.5k €" (en); por debajo de mil, "200 €".
  String _compact(double v) {
    final format = NumberFormat('0.#', Intl.canonicalizedLocale(locale));
    if (v.abs() >= 1000) return '${format.format(v / 1000)}k €';
    return '${format.format(v)} €';
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final t in ticks) {
      final tp = TextPainter(
        text: TextSpan(
          text: _compact(t),
          style: TextStyle(fontSize: 10, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 6);
      final y = scale.y(t) - tp.height / 2;
      tp.paint(canvas, Offset(size.width - 6 - tp.width, y));
    }
  }

  @override
  bool shouldRepaint(_AxisLabelsPainter old) =>
      old.ticks != ticks || old.color != color || old.locale != locale;
}

/// Barra apilada por método (separadores de 2px, extremo superior redondeado
/// 4px) y marca horizontal del beneficio neto con anillo del color de fondo.
class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.group,
    required this.scale,
    required this.methods,
    required this.methodColors,
    required this.surface,
    required this.ink,
  });

  final _Group group;
  final _Scale scale;
  final List<PaymentMethod> methods;
  final Map<PaymentMethod, Color> methodColors;
  final Color surface;
  final Color ink;

  static const double _barWidth = 22;
  static const double _gap = 2;
  static const double _radius = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final left = cx - _barWidth / 2;
    final right = cx + _barWidth / 2;

    // Segmentos apilados desde la base (0)
    final segments = [
      for (final m in methods)
        if ((group.methods[m] ?? 0) > 0.005) (m, group.methods[m]!),
    ];
    // Si no hay desglose (datos raros), una única barra neutra con el total
    if (segments.isEmpty && group.revenue > 0) {
      segments.add((PaymentMethod.unspecified, group.revenue));
    }

    var bottomValue = 0.0;
    for (var i = 0; i < segments.length; i++) {
      final (method, value) = segments[i];
      final isTop = i == segments.length - 1;
      final yBottom = scale.y(bottomValue) - (i == 0 ? 0 : _gap / 2);
      final yTop = scale.y(bottomValue + value) + (isTop ? 0 : _gap / 2);
      bottomValue += value;
      if (yBottom - yTop < 0.5) continue;

      final rect = Rect.fromLTRB(left, yTop, right, yBottom);
      final paint = Paint()
        ..color = methodColors[method] ?? const Color(0xFF9A9994);
      if (isTop) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(_radius),
            topRight: const Radius.circular(_radius),
          ),
          paint,
        );
      } else {
        canvas.drawRect(rect, paint);
      }
    }

    // Marca de beneficio neto: línea de 2px con anillo de fondo
    final yNet = scale.y(group.net);
    final markerLeft = left - 6;
    final markerRight = right + 6;
    canvas.drawLine(
      Offset(markerLeft, yNet),
      Offset(markerRight, yNet),
      Paint()
        ..color = surface
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(markerLeft, yNet),
      Offset(markerRight, yNet),
      Paint()
        ..color = ink
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.group != group ||
      old.surface != surface ||
      old.ink != ink ||
      old.scale.max != scale.max ||
      old.scale.min != scale.min;
}
