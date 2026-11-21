import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../services/app_preferences.dart';
import 'app_ui.dart';

/// Un paso de una guía: qué elemento se ilumina y qué se dice de él.
class CoachStep {
  const CoachStep({required this.target, required this.text, this.title});

  /// Clave del widget que se resalta (debe estar en pantalla).
  final GlobalKey target;
  final String? title;
  final String text;
}

/// Guía "mini tutorial" sobre la propia pantalla: oscurece el fondo, ilumina un
/// elemento y lo explica en una burbuja corta. El hueco iluminado deja pasar
/// los toques, así que se puede probar el elemento en el momento.
abstract final class CoachMarks {
  /// Muestra los [steps] uno a uno. Los que no estén en pantalla se saltan.
  /// Devuelve cuando se termina o se salta.
  static Future<void> show(
    BuildContext context, {
    required List<CoachStep> steps,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || steps.isEmpty) return Future.value();
    final completer = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CoachOverlay(
        steps: steps,
        onClose: () {
          if (completer.isCompleted) return;
          entry.remove();
          completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

/// Capa con el recorte y la burbuja. Pública para poder probarla.
class CoachOverlay extends StatefulWidget {
  const CoachOverlay({super.key, required this.steps, required this.onClose});

  final List<CoachStep> steps;
  final VoidCallback onClose;

  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<CoachOverlay> {
  /// Pasos con su elemento en pantalla, en el momento de empezar.
  late List<CoachStep> _steps;
  int _index = 0;
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    _steps = widget.steps;
    WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(0));
  }

  Rect? _measure(GlobalKey key) {
    final context = key.currentContext;
    final box = context?.findRenderObject();
    if (context == null || box is! RenderBox || !box.attached) return null;
    if (!box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Va al paso [index]: lo trae a la vista, lo mide y salta los que no existan.
  Future<void> _goTo(int index) async {
    var i = index;
    while (i < _steps.length) {
      final context = _steps[i].target.currentContext;
      if (context != null) {
        try {
          await Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
          );
        } catch (_) {
          // Sin Scrollable: ya está a la vista
        }
        if (!mounted) return;
        final rect = _measure(_steps[i].target);
        if (rect != null) {
          setState(() {
            _index = i;
            _rect = rect;
          });
          return;
        }
      }
      i++;
    }
    widget.onClose();
  }

  void _next() {
    if (_index + 1 >= _steps.length) {
      widget.onClose();
    } else {
      _goTo(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = _rect;
    if (rect == null) return const SizedBox.shrink();
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final hole = rect.inflate(6);
    final step = _steps[_index];
    final last = _index == _steps.length - 1;

    // La burbuja va debajo del elemento si este está en la mitad de arriba
    final below = hole.center.dy < screen.height * 0.55;
    final width = (screen.width - 32).clamp(0.0, 360.0);
    final left = (hole.center.dx - width / 2).clamp(
      16.0,
      (screen.width - width - 16).clamp(16.0, double.infinity),
    );

    Widget absorber(Rect r) => Positioned.fromRect(
      rect: r,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const SizedBox.expand(),
      ),
    );

    return Stack(
      children: [
        // Fondo oscuro con un hueco en el elemento (solo se pinta)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SpotlightPainter(hole)),
          ),
        ),
        // Cuatro bandas que absorben los toques alrededor del hueco; el hueco
        // queda libre para tocar el elemento de verdad
        absorber(Rect.fromLTRB(0, 0, screen.width, hole.top)),
        absorber(Rect.fromLTRB(0, hole.bottom, screen.width, screen.height)),
        absorber(Rect.fromLTRB(0, hole.top, hole.left, hole.bottom)),
        absorber(
          Rect.fromLTRB(hole.right, hole.top, screen.width, hole.bottom),
        ),
        Positioned(
          left: left,
          width: width,
          top: below ? hole.bottom + 12 : null,
          bottom: below ? null : screen.height - hole.top + 12,
          child: SafeArea(
            top: false,
            bottom: false,
            minimum: EdgeInsets.only(top: padding.top > 0 && below ? 0 : 0),
            child: _Bubble(
              step: step,
              index: _index,
              total: _steps.length,
              last: last,
              onNext: _next,
              onSkip: widget.onClose,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.hole);

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      hole,
      const Radius.circular(AppRadius.lg),
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.step,
    required this.index,
    required this.total,
    required this.last,
    required this.onNext,
    required this.onSkip,
  });

  final CoachStep step;
  final int index;
  final int total;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.title != null) ...[
              Text(
                step.title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(step.text, style: const TextStyle(fontSize: 14, height: 1.35)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: total > 1
                      ? Text(
                          context.l10n.coachStepCount(index + 1, total),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Wrap: en un ancho estrecho los botones pasan a otra línea
                Flexible(
                  flex: 3,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    children: [
                      if (!last)
                        TextButton(
                          onPressed: onSkip,
                          child: Text(context.l10n.coachSkip),
                        ),
                      FilledButton(
                        onPressed: onNext,
                        child: Text(
                          last
                              ? context.l10n.coachDone
                              : context.l10n.coachNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Guías por pantalla: salen solas la primera vez y se pueden repetir.
abstract final class CoachGuide {
  /// Muestra la guía [id] solo si no se ha visto, tras una breve espera para
  /// que la pantalla termine de montarse. No sale si aún no se ha visto el
  /// tutorial de bienvenida ni si hay otra pantalla encima.
  static Future<void> showOnce(
    BuildContext context,
    String id,
    List<CoachStep> Function() steps,
  ) async {
    if (AppPreferences.isCoachSeen(id) || !AppPreferences.tutorialSeen) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    await replay(context, id, steps);
  }

  /// Muestra la guía [id] (aunque ya se haya visto) y la da por vista.
  static Future<void> replay(
    BuildContext context,
    String id,
    List<CoachStep> Function() steps,
  ) async {
    await AppPreferences.markCoachSeen(id);
    if (!context.mounted) return;
    await CoachMarks.show(context, steps: steps());
  }
}
