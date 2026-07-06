import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Canonical visual mapping for a subject/topic's mastery state.
/// Single source of truth — do not re-implement this switch elsewhere.
class MasteryVisuals {
  MasteryVisuals._();

  static const List<String> states = ['WEAK', 'LEARNING', 'PRACTICING', 'MASTERED'];

  static Color colorFor(String state, AskAideColors c) {
    switch (state.toUpperCase()) {
      case 'WEAK':
        return c.error;
      case 'LEARNING':
        return c.warning;
      case 'PRACTICING':
        return c.success;
      default:
        return c.accentSecondary; // MASTERED + unknown
    }
  }

  static String emojiFor(String state) => switch (state.toUpperCase()) {
        'WEAK' => '🔴',
        'LEARNING' => '🟡',
        'PRACTICING' => '🟢',
        'MASTERED' => '🏆',
        _ => '⚪',
      };

  static String labelFor(String state) => switch (state.toUpperCase()) {
        'WEAK' => 'Weak',
        'LEARNING' => 'Learning',
        'PRACTICING' => 'Practicing',
        'MASTERED' => 'Mastered',
        _ => state,
      };
}

/// Canonical visual mapping for question/paper difficulty.
class DifficultyVisuals {
  DifficultyVisuals._();

  static Color colorFor(String difficulty, AskAideColors c) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return c.success;
      case 'medium':
        return c.warning;
      case 'hard':
        return c.error;
      default:
        return c.info; // unrecognized/other
    }
  }
}
