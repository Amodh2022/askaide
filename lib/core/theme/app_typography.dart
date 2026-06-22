import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for "Quiet Scholar":
///  - Fraunces (serif)      → all headings, display numbers (italic for emphasis)
///  - Inter Tight (sans)    → body & UI
///  - JetBrains Mono (mono) → small UPPERCASE labels with wide tracking
///
/// All factories take the resolved foreground [color] so the same scale works
/// in light and dark.
class AppTypography {
  AppTypography._();

  // ---- Display / headings (Fraunces) -------------------------------------
  static TextStyle display(Color color) => GoogleFonts.fraunces(
        color: color,
        fontSize: 64,
        height: 0.92,
        fontWeight: FontWeight.w600,
        letterSpacing: -2.0,
      );

  static TextStyle h1(Color color) => GoogleFonts.fraunces(
        color: color,
        fontSize: 44,
        height: 1.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.2,
      );

  static TextStyle h2(Color color) => GoogleFonts.fraunces(
        color: color,
        fontSize: 32,
        height: 1.05,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      );

  static TextStyle h3(Color color) => GoogleFonts.fraunces(
        color: color,
        fontSize: 24,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      );

  static TextStyle h4(Color color) => GoogleFonts.fraunces(
        color: color,
        fontSize: 20,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Serif used for emphasis words inside headings (often italic).
  static TextStyle serifEmphasis(Color color, {double size = 32}) =>
      GoogleFonts.fraunces(
        color: color,
        fontSize: size,
        height: 1.05,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
      );

  /// Big stat / count-up number.
  static TextStyle statNumber(Color color, {double size = 48}) =>
      GoogleFonts.fraunces(
        color: color,
        fontSize: size,
        height: 0.95,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
      );

  // ---- Body & UI (Inter Tight) -------------------------------------------
  static TextStyle bodyLarge(Color color) => GoogleFonts.interTight(
        color: color,
        fontSize: 17,
        height: 1.55,
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.interTight(
        color: color,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodySmall(Color color) => GoogleFonts.interTight(
        color: color,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
      );

  static TextStyle labelLarge(Color color) => GoogleFonts.interTight(
        color: color,
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle button(Color color) => GoogleFonts.interTight(
        color: color,
        fontSize: 15,
        height: 1.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  // ---- Mono section labels (JetBrains Mono) ------------------------------
  /// The "— SECTION LABEL" tags: small, UPPERCASE, wide tracking.
  static TextStyle sectionLabel(Color color) => GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
      );

  static TextStyle mono(Color color, {double size = 13}) =>
      GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: size,
        height: 1.4,
        fontWeight: FontWeight.w400,
      );

  /// Builds a Material [TextTheme] so stock widgets inherit our fonts. We map:
  /// display/headline → Fraunces, title/body/label → Inter Tight.
  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: display(primary),
      displayMedium: h1(primary),
      displaySmall: h2(primary),
      headlineMedium: h3(primary),
      headlineSmall: h4(primary),
      titleLarge: GoogleFonts.interTight(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: labelLarge(primary),
      titleSmall: GoogleFonts.interTight(
        color: secondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: bodyLarge(primary),
      bodyMedium: bodyMedium(secondary),
      bodySmall: bodySmall(secondary),
      labelLarge: button(primary),
      labelMedium: sectionLabel(secondary),
      labelSmall: mono(secondary, size: 11),
    );
  }
}
