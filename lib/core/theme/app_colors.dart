import 'package:flutter/material.dart';

/// "Quiet Scholar" design-system palette, exposed as a [ThemeExtension] so every
/// widget reads colors from `Theme.of(context).extension<AskAideColors>()`
/// (or the `context.colors` helper) — the single source of truth that makes
/// light/dark swapping "just work".
@immutable
class AskAideColors extends ThemeExtension<AskAideColors> {
  const AskAideColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgCard,
    required this.bgRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderSubtle,
    required this.accent,
    required this.accentLight,
    required this.accentSecondary,
    required this.danger,
    required this.success,
    required this.successBg,
    required this.error,
    required this.errorBg,
    required this.warning,
    required this.warningBg,
    required this.info,
    required this.infoBg,
  });

  // Surfaces
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgCard;
  final Color bgRaised;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Lines
  final Color border;
  final Color borderSubtle;

  // Brand
  final Color accent;
  final Color accentLight;
  final Color accentSecondary; // mustard
  final Color danger;

  // Semantic
  final Color success;
  final Color successBg;
  final Color error;
  final Color errorBg;
  final Color warning;
  final Color warningBg;
  final Color info;
  final Color infoBg;

  /// LIGHT — "Quiet Scholar". Values verbatim from the design tokens.
  static const AskAideColors light = AskAideColors(
    bgPrimary: Color(0xFFF4F1EA),
    bgSecondary: Color(0xFFEDEAE0),
    bgCard: Color(0xFFFBF9F3),
    bgRaised: Color(0xFFF0EDE4),
    textPrimary: Color(0xFF1A1D1A),
    textSecondary: Color(0xFF3D4039),
    textMuted: Color(0xFF6B6A62),
    border: Color(0xFFD9D4C7),
    borderSubtle: Color(0xFFE3DFD4),
    accent: Color(0xFF2E5D4F),
    accentLight: Color(0xFFE4EFE8),
    accentSecondary: Color(0xFFE8D16A),
    danger: Color(0xFFA34A3C),
    success: Color(0xFF16A34A),
    successBg: Color(0xFFE6F4EA),
    error: Color(0xFFC0392B),
    errorBg: Color(0xFFF7E6E3),
    warning: Color(0xFFD97706),
    warningBg: Color(0xFFFBEEDC),
    info: Color(0xFF2563EB),
    infoBg: Color(0xFFE4ECFB),
  );

  /// DARK — given tokens verbatim; missing tokens derived to stay on-palette.
  static const AskAideColors dark = AskAideColors(
    bgPrimary: Color(0xFF14140F),
    bgSecondary: Color(0xFF1A1A13),
    bgCard: Color(0xFF211F1A),
    bgRaised: Color(0xFF2A2823),
    textPrimary: Color(0xFFF1EEDF),
    textSecondary: Color(0xFFC9C6B8),
    textMuted: Color(0xFF8F8C7E),
    border: Color(0xFF2A2A22),
    borderSubtle: Color(0xFF232319),
    accent: Color(0xFF8FBFA8),
    accentLight: Color(0xFF1E2A24),
    accentSecondary: Color(0xFFD8B94A),
    danger: Color(0xFFD88A7A),
    success: Color(0xFF4ADE80),
    successBg: Color(0xFF132A1C),
    error: Color(0xFFE57368),
    errorBg: Color(0xFF2C1714),
    warning: Color(0xFFF0A33E),
    warningBg: Color(0xFF2C2110),
    info: Color(0xFF6FA0F5),
    infoBg: Color(0xFF141F33),
  );

  @override
  AskAideColors copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgCard,
    Color? bgRaised,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderSubtle,
    Color? accent,
    Color? accentLight,
    Color? accentSecondary,
    Color? danger,
    Color? success,
    Color? successBg,
    Color? error,
    Color? errorBg,
    Color? warning,
    Color? warningBg,
    Color? info,
    Color? infoBg,
  }) {
    return AskAideColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgCard: bgCard ?? this.bgCard,
      bgRaised: bgRaised ?? this.bgRaised,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
    );
  }

  @override
  AskAideColors lerp(ThemeExtension<AskAideColors>? other, double t) {
    if (other is! AskAideColors) return this;
    return AskAideColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgRaised: Color.lerp(bgRaised, other.bgRaised, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
    );
  }
}

/// Ergonomic access: `context.colors.accent`.
extension AskAideColorsX on BuildContext {
  AskAideColors get colors =>
      Theme.of(this).extension<AskAideColors>() ?? AskAideColors.light;
}
