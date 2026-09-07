import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

abstract final class AppAlerts {
  // --- 💡 COLA Y ESTADO DE CONTROL DE ALERTAS ---
  static final Queue<_AlertTask> _queue = Queue<_AlertTask>();
  static bool _isShowing = false;

  // --- ALERTAS DE ÉXITO ---
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _enqueueAlert(
      context: context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
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
    _enqueueAlert(
      context: context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Theme.of(context).colorScheme.error,
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
    _enqueueAlert(
      context: context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange.shade800,
      textColor: Colors.white,
      duration: duration,
    );
  }

  // --- ALERTAS DE INFORMACIÓN ---
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _enqueueAlert(
      context: context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
      duration: duration,
    );
  }

  // --- 💡 GESTOR DE COLA (ENQUEUE) ---
  static void _enqueueAlert({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Duration duration,
  }) {
    _queue.add(
      _AlertTask(
        context: context,
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        duration: duration,
      ),
    );

    _processQueue();
  }

  // --- 💡 PROCESADOR SECUENCIAL DE LA COLA ---
  static void _processQueue() async {
    if (_isShowing || _queue.isEmpty) return;

    _isShowing = true;
    final task = _queue.removeFirst();

    if (!task.context.mounted) {
      _isShowing = false;
      _processQueue();
      return;
    }

    final messenger = ScaffoldMessenger.of(task.context);

    // Mostramos el SnackBar
    final snackBarController = messenger.showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: task.backgroundColor,
        duration: task.duration,
        content: Row(
          children: [
            Icon(task.icon, color: task.textColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.message,
                style: TextStyle(
                  color: task.textColor,
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
          textColor: task.textColor.withValues(alpha: 0.7),
          onPressed: () {
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Esperamos exactamente lo que dura el snackbar (más una pequeña pausa para la animación de salida)
    try {
      await snackBarController.closed;
    } catch (_) {
      // Por seguridad si el controlador se destruye de forma abrupta
      await Future.delayed(task.duration);
    }

    // Pequeño respiro entre snackbars consecutivos
    await Future.delayed(const Duration(milliseconds: 150));

    _isShowing = false;
    _processQueue(); // Llamamos al siguiente elemento de la cola
  }
}

// --- 💡 CLASE AUXILIAR PARA GUARDAR LOS DATOS DE LA TAREA ---
class _AlertTask {
  final BuildContext context;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Duration duration;

  _AlertTask({
    required this.context,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
  });
}
