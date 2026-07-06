/// Question formats shared by the practice/study flow and the question-paper
/// generator.
enum QuestionType {
  mcq,
  fillInTheBlank;

  static QuestionType fromApi(String? raw) {
    switch (raw?.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'fillintheblank':
      case 'fillintheblanks':
      case 'fillblank':
      case 'fillblanks':
      case 'fitb':
        return QuestionType.fillInTheBlank;
      case 'mcq':
      case 'multiplechoice':
      default:
        return QuestionType.mcq;
    }
  }

  /// Wire value for the study/practice session endpoints.
  String get apiValue => switch (this) {
        QuestionType.mcq => 'mcq',
        QuestionType.fillInTheBlank => 'fill-in-the-blank',
      };

  /// Wire value for the question-paper generation endpoints, which use a
  /// different (no-hyphen) spelling than the study/practice endpoints.
  String get paperApiValue => switch (this) {
        QuestionType.mcq => 'mcq',
        QuestionType.fillInTheBlank => 'fillblanks',
      };

  String get label => switch (this) {
        QuestionType.mcq => 'Multiple Choice',
        QuestionType.fillInTheBlank => 'Fill in the Blank',
      };

  /// Short label for compact UI (e.g. selector chips).
  String get chipLabel => switch (this) {
        QuestionType.mcq => 'MCQ',
        QuestionType.fillInTheBlank => 'Fill Blanks',
      };
}
