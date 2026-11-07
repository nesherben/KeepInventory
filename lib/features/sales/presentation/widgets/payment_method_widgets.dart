import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../domain/payment_method.dart';

/// Apariencia (icono, color y nombre) de cada método de pago.
extension PaymentMethodUi on PaymentMethod {
  IconData get icon => switch (this) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.paypal => Icons.paypal,
    PaymentMethod.bizum => Icons.phone_iphone,
    PaymentMethod.unspecified => Icons.help_outline,
  };

  /// Color fijo de cada método (paleta categórica validada para daltonismo,
  /// con su variante para modo oscuro). Úsalo en iconos y marcas, no en texto.
  Color colorOf(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      PaymentMethod.cash =>
        dark ? const Color(0xFF199E70) : const Color(0xFF1BAF7A),
      PaymentMethod.paypal =>
        dark ? const Color(0xFF3987E5) : const Color(0xFF2A78D6),
      PaymentMethod.bizum =>
        dark ? const Color(0xFFD95926) : const Color(0xFFEB6834),
      // Neutro: no compite con los colores de los métodos reales
      PaymentMethod.unspecified =>
        dark ? const Color(0xFF8A8986) : const Color(0xFF9A9994),
    };
  }

  String label(BuildContext context) => switch (this) {
    PaymentMethod.cash => context.l10n.paymentCash,
    PaymentMethod.paypal => context.l10n.paymentPaypal,
    PaymentMethod.bizum => context.l10n.paymentBizum,
    PaymentMethod.unspecified => context.l10n.paymentUnspecified,
  };
}

/// Selector de método de pago del carrito: un botón grande por método.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final method in PaymentMethod.selectable) ...[
          if (method != PaymentMethod.selectable.first)
            const SizedBox(width: 8),
          Expanded(child: _buildOption(context, theme, method)),
        ],
      ],
    );
  }

  Widget _buildOption(
    BuildContext context,
    ThemeData theme,
    PaymentMethod method,
  ) {
    final isSelected = method == selected;
    return Semantics(
      selected: isSelected,
      button: true,
      label: method.label(context),
      child: Material(
        color: isSelected
            ? method.colorOf(context).withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? method.colorOf(context) : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(method),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  method.icon,
                  color: isSelected
                      ? method.colorOf(context)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  method.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta compacta (icono + nombre) para tickets y devoluciones.
class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.method, this.text});

  final PaymentMethod method;

  /// Texto alternativo al nombre del método.
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: method.colorOf(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(method.icon, size: 14, color: method.colorOf(context)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text ?? method.label(context),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desglose de importes por método (solo los que tienen importe salvo
/// [showZero]). [format] permite ocultar cifras (modo privacidad).
class PaymentMethodTotals extends StatelessWidget {
  const PaymentMethodTotals({
    super.key,
    required this.totals,
    this.showZero = false,
    this.format,
  });

  final Map<PaymentMethod, double> totals;
  final bool showZero;
  final String Function(double amount)? format;

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? (double a) => '${a.toStringAsFixed(2)} €';
    final entries = totals.entries
        .where((e) => showZero || e.value.abs() >= 0.005)
        .toList();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final e in entries)
          PaymentMethodBadge(
            method: e.key,
            text: '${e.key.label(context)}  ${fmt(e.value)}',
          ),
      ],
    );
  }
}
