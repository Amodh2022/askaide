import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Builds the light/dark [ThemeData]. Every visual decision flows from
/// [AskAideColors] + [AppTypography] + [AppRadii], so the two themes differ
/// only by which [AskAideColors] instance they carry.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light, AskAideColors.light);
  static ThemeData dark() => _build(Brightness.dark, AskAideColors.dark);

  static ThemeData _build(Brightness brightness, AskAideColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: brightness == Brightness.dark
          ? const Color(0xFF14140F)
          : Colors.white,
      secondary: c.accentSecondary,
      onSecondary: const Color(0xFF1A1D1A),
      error: c.error,
      onError: Colors.white,
      surface: c.bgCard,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.bgRaised,
      outline: c.border,
      outlineVariant: c.borderSubtle,
    );

    final textTheme = AppTypography.textTheme(c.textPrimary, c.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgPrimary,
      canvasColor: c.bgPrimary,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: c.borderSubtle, thickness: 1),
      iconTheme: IconThemeData(color: c.textSecondary, size: 20),

      // Pill buttons (radius 99).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillR),
          textStyle: AppTypography.button(scheme.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillR),
          textStyle: AppTypography.button(c.textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: AppTypography.button(c.accent),
        ),
      ),

      cardTheme: CardThemeData(
        color: c.bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardR,
          side: BorderSide(color: c.borderSubtle),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTypography.bodyMedium(c.textMuted),
        labelStyle: AppTypography.bodyMedium(c.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.modalR,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.modalR,
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.modalR,
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.modalR,
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.accentLight,
        labelStyle: AppTypography.mono(c.accent, size: 11),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillR),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: c.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h4(c.textPrimary),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.modalR),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bgCard,
        selectedItemColor: c.accent,
        unselectedItemColor: c.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: AppTypography.bodyMedium(c.bgPrimary),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.modalR),
      ),
    );
  }
}
