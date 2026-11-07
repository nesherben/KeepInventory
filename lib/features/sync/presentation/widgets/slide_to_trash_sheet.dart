import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/shared_widgets/app_ui.dart';

/// Último paso del borrado total: arrastrar la base de datos a la papelera.
///
/// Devuelve `true` solo si el usuario la suelta dentro de la papelera;
/// `false`/`null` si cancela o cierra la hoja.
Future<bool> showSlideToTrashSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: true,
    showDragHandle: true,
    builder: (_) => const SlideToTrashSheet(),
  );
  return result == true;
}

class SlideToTrashSheet extends StatelessWidget {
  const SlideToTrashSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.trashSlideTitle,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.trashSlideHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            SlideToTrash(onCompleted: () => Navigator.pop(context, true)),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pista con la base de datos a la izquierda y una papelera a la derecha.
///
/// - Arrastrar mueve la base de datos; la papelera crece y se abre al
///   acercarse.
/// - Soltar antes del 90 % la devuelve a su sitio.
/// - Soltar al final la "tira": encoge dentro de la papelera, esta se sacude
///   (con vibración) y entonces llama a [onCompleted].
class SlideToTrash extends StatefulWidget {
  const SlideToTrash({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  static const thumbKey = ValueKey('slide-to-trash-thumb');

  @override
  State<SlideToTrash> createState() => _SlideToTrashState();
}

class _SlideToTrashState extends State<SlideToTrash>
    with TickerProviderStateMixin {
  static const double _height = 68;
  static const double _thumb = 56;
  static const double _padding = 6;
  static const double _threshold = 0.9;

  double _dx = 0;
  double _maxDx = 1;
  bool _completing = false;

  late final AnimationController _returnController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Animation<double>? _returnAnimation;

  /// 0 → 1: la base de datos cae dentro de la papelera y esta se sacude.
  late final AnimationController _throwController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  double get _progress => (_dx / _maxDx).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _returnController.addListener(() {
      setState(() => _dx = _returnAnimation?.value ?? 0);
    });
    _throwController.addListener(() => setState(() {}));
    _throwController.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _returnController.dispose();
    _throwController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_completing) return;
    _returnController.stop();
    final wasNear = _progress >= _threshold;
    setState(() => _dx = (_dx + details.delta.dx).clamp(0.0, _maxDx));
    // Pequeño "clic" al entrar en la zona de soltar
    if (!wasNear && _progress >= _threshold) HapticFeedback.selectionClick();
  }

  void _onDragEnd(DragEndDetails _) {
    if (_completing) return;
    if (_progress >= _threshold) {
      _completing = true;
      setState(() => _dx = _maxDx);
      HapticFeedback.heavyImpact();
      _throwController.forward();
    } else {
      _returnAnimation = Tween(begin: _dx, end: 0.0).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOutBack),
      );
      _returnController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final danger = colors.error;
    final near = _progress >= _threshold;
    final t = _throwController.value;

    // Al tirar: la base de datos encoge y se desvanece (primer 55 %)
    final fall = Curves.easeIn.transform((t / 0.55).clamp(0.0, 1.0));
    // La papelera se sacude después (último 60 %)
    final shakePhase = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    final shake = math.sin(shakePhase * math.pi * 5) * (1 - shakePhase) * 0.25;

    // Papelera: crece al acercarse y "se abre" cerca del final
    final binScale = 1 + 0.35 * _progress;

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDx = math.max(1, constraints.maxWidth - _thumb - _padding * 2);

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              danger.withValues(alpha: 0.06 + 0.10 * _progress),
              Theme.of(context).cardColor,
            ),
            borderRadius: BorderRadius.circular(_height / 2),
            border: Border.all(color: danger.withValues(alpha: 0.35)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Texto guía (se desvanece al arrastrar)
              Center(
                child: Opacity(
                  opacity: _completing
                      ? 0
                      : (1 - _progress * 1.6).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _thumb),
                    child: Text(
                      context.l10n.trashSlideDrag,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              // Texto "Suelta para borrar" en la zona final
              if (near && !_completing)
                Positioned(
                  left: _padding + 8,
                  child: Text(
                    context.l10n.trashSlideRelease,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: danger,
                    ),
                  ),
                ),
              // Papelera
              Positioned(
                right: _padding,
                child: SizedBox(
                  width: _thumb,
                  height: _thumb,
                  child: Transform.rotate(
                    angle: shake,
                    child: Transform.scale(
                      scale: _completing ? 1.35 : binScale,
                      child: Icon(
                        near || _completing
                            ? Icons.delete
                            : Icons.delete_outline,
                        size: 32,
                        color: danger,
                      ),
                    ),
                  ),
                ),
              ),
              // Base de datos arrastrable
              Positioned(
                left: _padding + _dx,
                child: Opacity(
                  opacity: 1 - fall,
                  child: Transform.translate(
                    // Al caer, baja un poco "dentro" de la papelera
                    offset: Offset(0, 10 * fall),
                    child: Transform.scale(
                      scale: 1 - 0.8 * fall,
                      child: GestureDetector(
                        key: SlideToTrash.thumbKey,
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                        child: Container(
                          width: _thumb,
                          height: _thumb,
                          decoration: BoxDecoration(
                            color: danger,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.storage,
                            color: colors.onError,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
