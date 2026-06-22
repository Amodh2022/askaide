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

  String get apiValue => name; // 'easy' | 'medium' | 'hard'
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };
}

/// Question formats the practice screen renders.
enum QuestionType {
  mcq,
  fillInTheBlank;

  static QuestionType fromApi(String? raw) {
    switch (raw?.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'fillintheblank':
      case 'fillblank':
      case 'fitb':
        return QuestionType.fillInTheBlank;
      case 'mcq':
      case 'multiplechoice':
      default:
        return QuestionType.mcq;
    }
  }

  String get apiValue => switch (this) {
        QuestionType.mcq => 'mcq',
        QuestionType.fillInTheBlank => 'fill-in-the-blank',
      };

  String get label => switch (this) {
        QuestionType.mcq => 'Multiple Choice',
        QuestionType.fillInTheBlank => 'Fill in the Blank',
      };
}
