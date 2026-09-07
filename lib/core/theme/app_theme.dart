import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light({Color? dynamicPrimary}) =>
      _buildTheme(Brightness.light, dynamicPrimary: dynamicPrimary);

  static ThemeData dark({Color? dynamicPrimary}) =>
      _buildTheme(Brightness.dark, dynamicPrimary: dynamicPrimary);

  static ThemeData _buildTheme(Brightness brightness, {Color? dynamicPrimary}) {
    final isDark = brightness == Brightness.dark;
    final fallbackPrimary =
        dynamicPrimary ?? (isDark ? AppColors.darkPrimary : AppColors.primary);

    final fallbackScheme =
        ColorScheme.fromSeed(
          seedColor: fallbackPrimary,
          brightness: brightness,
        ).copyWith(
          primary: fallbackPrimary,
          // 💡 SOLUCIÓN HIGHLIGHT: Forzamos el color de selección para los Grids
          primaryContainer: isDark
              ? AppColors.darkPrimary.withValues(alpha: 0.2)
              : AppColors.primarySoft,
          onPrimary: isDark ? AppColors.darkOnPrimary : AppColors.onPrimary,
          secondary: isDark ? AppColors.darkAccent : AppColors.accent,
          tertiary: AppColors.success,
          error: AppColors.danger,
          surface: isDark ? AppColors.darkSurface : AppColors.surface,
          onSurface: isDark ? AppColors.darkText : AppColors.text,
          onSurfaceVariant: isDark
              ? AppColors.darkTextMuted
              : AppColors.textMuted,
          outline: isDark ? AppColors.darkOutline : AppColors.outline,
          outlineVariant: isDark
              ? AppColors.darkOutlineSoft
              : AppColors.outlineSoft,
        );

    final colorScheme = fallbackScheme;
    final surface = colorScheme.surface;
    final text = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final outline = colorScheme.outline;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final danger = colorScheme.error;

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: ThemeData(
        brightness: brightness,
        colorScheme: colorScheme,
      ).textTheme.apply(bodyColor: text, displayColor: text),
      cardTheme: CardThemeData(color: surface, surfaceTintColor: surface),
      dividerTheme: DividerThemeData(color: outline),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: surface,
        foregroundColor: text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: _inputBorder(outline),
        enabledBorder: _inputBorder(outline),
        focusedBorder: _inputBorder(colorScheme.primary, width: 2),
        errorBorder: _inputBorder(danger),
        focusedErrorBorder: _inputBorder(danger, width: 2),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
