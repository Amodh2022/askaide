import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Non-color design tokens: radius, spacing, shadows. Kept const so they are
/// shared across light/dark without duplication.
class AppRadii {
  AppRadii._();

  static const double pill = 99; // buttons
  static const double card = 4; // cards, input fields
  static const double modal = 6; // modals, sheets
  static const double component = 8; // inner containers, badges
  static const double section = 12; // section cards, panels
  static const double chip = 99;

  static const BorderRadius pillR = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius modalR = BorderRadius.all(Radius.circular(modal));
  static const BorderRadius componentR = BorderRadius.all(Radius.circular(component));
  static const BorderRadius sectionR = BorderRadius.all(Radius.circular(section));
}

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double cardPad = 18; // standard card body padding
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Fixed left sidebar width on desktop.
  static const double sidebarWidth = 240;

  /// Width breakpoint separating mobile from desktop layout.
  static const double mobileBreakpoint = 768;
}

class AppShadows {
  AppShadows._();

  /// Low-opacity resting card shadow: `0 1px 3px + 0 4px 16px`.
  static List<BoxShadow> card(Brightness b) {
    final base = b == Brightness.dark ? Colors.black : const Color(0xFF1A1D1A);
    return [
      BoxShadow(
        color: base.withValues(alpha: b == Brightness.dark ? 0.30 : 0.05),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: base.withValues(alpha: b == Brightness.dark ? 0.35 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Editorial float: `0 20px 50px rgba(26,29,26,0.08)`.
  static List<BoxShadow> editorial(Brightness b) => [
        BoxShadow(
          color: const Color(0xFF1A1D1A)
              .withValues(alpha: b == Brightness.dark ? 0.45 : 0.08),
          blurRadius: 50,
          offset: const Offset(0, 20),
        ),
      ];
}

/// Reusable [BoxDecoration] builders that already pull from [AskAideColors].
extension AppDecorations on BuildContext {
  BoxDecoration cardDecoration({bool raised = false}) {
    final c = colors;
    final brightness = Theme.of(this).brightness;
    return BoxDecoration(
      color: raised ? c.bgRaised : c.bgCard,
      borderRadius: AppRadii.cardR,
      border: Border.all(color: c.borderSubtle),
      boxShadow: AppShadows.card(brightness),
    );
  }

  BoxDecoration editorialDecoration() {
    final c = colors;
    return BoxDecoration(
      color: c.bgCard,
      borderRadius: AppRadii.cardR,
      border: Border.all(color: c.border),
      boxShadow: AppShadows.editorial(Theme.of(this).brightness),
    );
  }
}
