part of '../question_paper_pages.dart';

/// The per-type "product" the [QuestionSectionFactory] builds: what a section
/// of questions of one [QuestionType] should be labeled and rendered like,
/// shared by both the screen preview and the PDF renderer.
class QuestionSectionSpec {
  const QuestionSectionSpec({
    required this.type,
    required this.sectionLabel,
    required this.sectionInstruction,
    required this.showOptions,
  });

  final QuestionType type;
  final String sectionLabel;
  final String sectionInstruction;
  final bool showOptions;
}

/// One group of same-type questions produced by [QuestionSectionFactory.groupSections].
class QuestionSectionGroup {
  const QuestionSectionGroup({required this.spec, required this.questions});

  final QuestionSectionSpec spec;
  final List<PaperQuestion> questions;
}

/// Factory Method for question-type-specific rendering data. Adding a new
/// [QuestionType] means adding one entry here — every consumer (screen
/// preview, PDF) picks it up automatically.
class QuestionSectionFactory {
  const QuestionSectionFactory._();

  static const Map<QuestionType, QuestionSectionSpec> _specs = {
    QuestionType.mcq: QuestionSectionSpec(
      type: QuestionType.mcq,
      sectionLabel: 'Section A — Multiple Choice Questions',
      sectionInstruction: 'Answer all questions. Choose the correct option.',
      showOptions: true,
    ),
    QuestionType.fillInTheBlank: QuestionSectionSpec(
      type: QuestionType.fillInTheBlank,
      sectionLabel: 'Section B — Fill in the Blanks',
      sectionInstruction: 'Fill in the blanks with the correct answer.',
      showOptions: false,
    ),
  };

  /// Fixed rendering order so MCQ always renders before Fill-in-the-Blank,
  /// matching the previous hardcoded Section A / Section B ordering.
  static const List<QuestionType> orderedTypes = [
    QuestionType.mcq,
    QuestionType.fillInTheBlank,
  ];

  static QuestionSectionSpec specFor(QuestionType type) => _specs[type]!;

  /// Groups [questions] by type in [orderedTypes] order, skipping empty
  /// groups. Questions with no type (`questionType == null`) are omitted —
  /// callers should fall back to a flat, unsectioned list when this returns
  /// fewer groups than there are questions (or an empty list).
  static List<QuestionSectionGroup> groupSections(List<PaperQuestion> questions) {
    final groups = <QuestionSectionGroup>[];
    for (final type in orderedTypes) {
      final matching = questions.where((q) => q.questionType == type).toList();
      if (matching.isNotEmpty) {
        groups.add(QuestionSectionGroup(spec: specFor(type), questions: matching));
      }
    }
    return groups;
  }
}
