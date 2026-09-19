import 'package:flutter/material.dart';

/// Texto de una sola línea.
///
/// - Si cabe en el ancho disponible, se ve como un [Text] normal.
/// - Si NO cabe, hace scroll automático hacia la izquierda hasta el final
///   del texto y, tras una pausa, vuelve a empezar desde el principio.
class AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Pausa antes de empezar y al llegar al final (antes de reiniciar).
  final Duration pause;

  /// Velocidad del desplazamiento en píxeles por segundo.
  final double velocity;

  const AutoScrollText(
    this.text, {
    super.key,
    this.style,
    this.pause = const Duration(seconds: 1),
    this.velocity = 40,
  });

  @override
  State<AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  final ScrollController _controller = ScrollController();
  bool _running = false;
  bool _disposed = false;

  bool get _canScroll => !_disposed && _controller.hasClients;

  @override
  void didUpdateWidget(covariant AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el texto (p. ej. al quitar un producto del carrito y
    // reutilizarse este widget para otro), volvemos al principio.
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loop() async {
    if (_running) return;
    _running = true;
    try {
      while (_canScroll) {
        await Future.delayed(widget.pause);
        if (!_canScroll) break;

        final max = _controller.position.maxScrollExtent;
        if (max <= 0) break; // Cabe entero: no hace falta animar.

        final duration = Duration(
          milliseconds: (max / widget.velocity * 1000).round(),
        );

        await _controller.animateTo(
          max,
          duration: duration,
          curve: Curves.linear,
        );
        if (!_canScroll) break;

        // Pausa al llegar al final y salto directo al inicio del texto.
        await Future.delayed(widget.pause);
        if (!_canScroll) break;

        _controller.jumpTo(0);
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al (re)construir intentamos arrancar el bucle. Si ya está en marcha
    // o el texto cabe, no hace nada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loop();
    });

    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
