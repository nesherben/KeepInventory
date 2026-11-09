import 'package:flutter/material.dart';

/// Panel inferior para elegir un nombre de una lista (ferias, categorías…):
/// buscador arriba, tocar un elemento lo elige, "Crear «X»" si lo escrito no
/// existe, papelera por elemento y, opcionalmente, "Quitar".
///
/// Devuelve el nombre elegido, `''` si se pulsó [removeLabel] o null si se
/// cerró sin elegir.
Future<String?> showNamePickerSheet(
  BuildContext context, {
  required String title,
  required String searchHint,
  required List<String> names,
  required String Function(String typed) createLabel,
  String? current,
  String? currentLabel,
  String? removeLabel,
  String? deleteTooltip,
  IconData icon = Icons.label_outline,

  /// Pregunta y borra un elemento; true si se borró (se quita de la lista).
  Future<bool> Function(BuildContext sheetContext, String name)? onDelete,
}) {
  final items = [...names];
  var query = '';

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        final colors = Theme.of(sheetContext).colorScheme;
        final typed = query.trim();
        final visible = items
            .where((n) => n.toLowerCase().contains(typed.toLowerCase()))
            .toList();
        final exactExists = items.any(
          (n) => n.toLowerCase() == typed.toLowerCase(),
        );
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: items.isEmpty,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) => setSheet(() => query = v),
                    // Enter: crea / elige lo escrito
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        Navigator.pop(sheetContext, v.trim());
                      }
                    },
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      if (typed.isNotEmpty && !exactExists)
                        ListTile(
                          leading: Icon(Icons.add, color: colors.primary),
                          title: Text(
                            createLabel(typed),
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => Navigator.pop(sheetContext, typed),
                        ),
                      for (final name in visible)
                        ListTile(
                          leading: Icon(icon),
                          title: Text(name),
                          selected: name == current,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (name == current && currentLabel != null)
                                Text(currentLabel),
                              if (onDelete != null)
                                IconButton(
                                  tooltip: deleteTooltip,
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  onPressed: () async {
                                    if (await onDelete(sheetContext, name)) {
                                      setSheet(() => items.remove(name));
                                      // Se borró el actual: no queda nada que elegir
                                      if (name == current &&
                                          sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),
                          onTap: () => Navigator.pop(sheetContext, name),
                        ),
                      if (removeLabel != null &&
                          current != null &&
                          current.isNotEmpty)
                        ListTile(
                          leading: Icon(
                            Icons.remove_circle_outline,
                            color: colors.error,
                          ),
                          title: Text(
                            removeLabel,
                            style: TextStyle(color: colors.error),
                          ),
                          onTap: () => Navigator.pop(sheetContext, ''),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Diálogo de confirmación de borrado (rojo), compartido por ferias y
/// categorías.
Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String cancelLabel,
  required String deleteLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(deleteLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
