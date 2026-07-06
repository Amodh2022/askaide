export '../../../../core/domain/question_type.dart';

/// Difficulty levels. Medium is the default selection in StudyConfig.
enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty fromApi(String? raw) =>
      Difficulty.values.firstWhere(
        (d) => d.name == raw?.toLowerCase(),
        orElse: () => Difficulty.medium,
      );

  // First letter capitalised: 'Easy' | 'Medium' | 'Hard'.
  String get apiValue => name[0].toUpperCase() + name.substring(1);
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };
}
