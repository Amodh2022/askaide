import 'package:equatable/equatable.dart';

import 'study_enums.dart';
import 'study_taxonomy.dart';

/// The fully-resolved selection that starts a practice session. Difficulty
/// defaults to [Difficulty.medium]. [isComplete] gates the "Start" button.
class StudyConfig extends Equatable {
  const StudyConfig({
    this.selectedClass,
    this.selectedSubject,
    this.selectedChapter,
    this.questionType = QuestionType.mcq,
    this.difficulty = Difficulty.medium,
  });

  final ClassOption? selectedClass;
  final SubjectOption? selectedSubject;
  final ChapterOption? selectedChapter;
  final QuestionType questionType;
  final Difficulty difficulty;

  bool get isComplete =>
      selectedClass != null &&
      selectedSubject != null &&
      selectedChapter != null;

  StudyConfig copyWith({
    ClassOption? selectedClass,
    SubjectOption? selectedSubject,
    ChapterOption? selectedChapter,
    QuestionType? questionType,
    Difficulty? difficulty,
    bool clearSubject = false,
    bool clearChapter = false,
  }) {
    return StudyConfig(
      selectedClass: selectedClass ?? this.selectedClass,
      selectedSubject:
          clearSubject ? null : (selectedSubject ?? this.selectedSubject),
      selectedChapter:
          clearChapter ? null : (selectedChapter ?? this.selectedChapter),
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  @override
  List<Object?> get props => [
        selectedClass,
        selectedSubject,
        selectedChapter,
        questionType,
        difficulty,
      ];
}
