import 'dart:async';

import 'package:flutter/material.dart';

abstract final class AppAlerts {
  // --- ALERTAS DE ÉXITO ---
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      // 💡 Texto blanco fijo
      textColor: Colors.white,
      duration: duration,
    );
  }

  // --- ALERTAS DE ERROR ---
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Theme.of(context).colorScheme.error,
      // 💡 Texto blanco fijo
      textColor: Colors.white,
      duration: duration,
    );
  }

  // --- ALERTAS DE ADVERTENCIA / AVISOS ---
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange.shade800,
      // 💡 Texto blanco fijo
      textColor: Colors.white,
      duration: duration,
    );
  }

  // --- ALERTAS DE INFORMACIÓN (El azul clarito) ---
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Theme.of(context).colorScheme.primary,
      // 💡 SOLO AQUÍ: Color adaptativo (se pondrá oscuro si el fondo primario es claro en modo oscuro)
      textColor: Theme.of(context).colorScheme.onPrimary,
      duration: duration,
    );
  }

  // --- CONSTRUCTOR PRIVADO DEL SNACKBAR ---
  static void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Limpiamos cualquier snackbar anterior
    messenger.clearSnackBars();

    // 2. Mostramos el nuevo Snackbar
    final controller = messenger.showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: backgroundColor,
        duration: duration,
        content: Row(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 28,
            ), // 💡 Aplica el color que toque
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor, // 💡 Aplica el color que toque
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: textColor.withValues(
            alpha: 0.7,
          ), // 💡 Aplica el color con un poco de transparencia
          onPressed: () {
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );

    // 3. Forzamos el cierre manual a los 3 segundos exactos
    Timer(duration, () {
      try {
        controller.close();
      } catch (_) {
        // Ignorar
      }
    });
  }
}
