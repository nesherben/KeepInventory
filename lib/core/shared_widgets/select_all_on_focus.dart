import 'package:flutter/material.dart';

/// Al ganar el foco un campo NUMÉRICO de [child], selecciona todo su valor para
/// poder escribir encima sin borrar a mano ("15" → tocar → teclear 10 → "10").
///
/// El `selectAllOnFocus` de Flutter no actúa en Android al tocar ni con
/// autofocus dentro de un panel, y un `Focus` solo avisa cuando el foco entra o
/// sale del conjunto, no cuando salta de un campo a otro. Por eso escucha el
/// foco global y actúa sobre cualquier campo del árbol (con o sin controlador
/// propio), sin tocar cada formulario. Los campos de texto (nombres) no se ven
/// afectados: ahí se suele querer añadir al final.
class SelectAllOnFocus extends StatefulWidget {
  const SelectAllOnFocus({super.key, required this.child});

  final Widget child;

  @override
  State<SelectAllOnFocus> createState() => _SelectAllOnFocusState();
}

class _SelectAllOnFocusState extends State<SelectAllOnFocus> {
  /// Último campo al que se le aplicó (para no volver a seleccionar mientras
  /// el usuario coloca el cursor en el mismo campo).
  FocusNode? _last;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    super.dispose();
  }

  /// El campo numérico con el foco dentro de este árbol (null si no hay).
  EditableText? _focusedNumericField() {
    EditableText? found;
    void visit(Element element) {
      if (found != null) return;
      final widget = element.widget;
      if (widget is EditableText) {
        // numberWithOptions comparte índice con number (decimales, con signo…)
        if (widget.focusNode.hasPrimaryFocus &&
            widget.keyboardType.index == TextInputType.number.index) {
          found = widget;
        }
        return;
      }
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
    return found;
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final field = _focusedNumericField();
    if (field == null) {
      _last = null;
      return;
    }
    if (identical(_last, field.focusNode)) return;
    _last = field.focusNode;
    // Tras el frame (con autofocus el campo aún no estaba listo) y de nuevo un
    // instante después: al tocar, el cursor se coloca al soltar el dedo y
    // desharía la selección
    WidgetsBinding.instance.addPostFrameCallback((_) => _select(field));
    Future.delayed(const Duration(milliseconds: 150), () => _select(field));
  }

  void _select(EditableText field) {
    if (!mounted || !field.focusNode.hasPrimaryFocus) return;
    final controller = field.controller;
    final length = controller.text.length;
    if (length == 0) return;
    try {
      controller.selection = TextSelection(baseOffset: 0, extentOffset: length);
    } catch (_) {
      // El campo ya se destruyó
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
