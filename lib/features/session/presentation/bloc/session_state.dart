part of 'session_bloc.dart';

/// Which view the main panel shows (driven by an AnimatedSwitcher in the UI).
enum SessionPanel { config, practice, review }

enum LoadStatus { idle, loading, success, failure }

/// Instant feedback for the question just answered.
class AnswerFeedback extends Equatable {
  const AnswerFeedback({
    required this.isCorrect,
    required this.correctAnswer,
    this.explanation,
  });
  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;
  @override
  List<Object?> get props => [isCorrect, correctAnswer, explanation];
}

/// End-of-session summary used by the result modal (mirrors React's
/// SessionResultModal props: score, total, derived accuracy).
class SessionSummary extends Equatable {
  const SessionSummary({required this.score, required this.total});
  final int score;
  final int total;

  int get incorrect => total - score;
  int get accuracyPercent => total == 0 ? 0 : ((score / total) * 100).round();

  @override
  List<Object?> get props => [score, total];
}

class SessionState extends Equatable {
  const SessionState({
    this.panel = SessionPanel.config,
    this.config = const StudyConfig(),
    this.classes = const [],
    this.subjects = const [],
    this.chapters = const [],
    this.taxonomyStatus = LoadStatus.idle,
    this.questionStatus = LoadStatus.idle,
    this.reviewStatus = LoadStatus.idle,
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.feedback,
    this.sessionStarted = false,
    this.activeSession,
    this.reviewSession,
    this.history = const [],
    this.isOnline = true,
    this.queuedCount = 0,
    this.errorMessage,
    this.resultSummary,
    this.npsHandled = false,
    this.npsEligible = false,
    this.finishing = false,
    this.mastered = false,
  });

  final SessionPanel panel;
  final StudyConfig config;

  final List<ClassOption> classes;
  final List<SubjectOption> subjects;
  final List<ChapterOption> chapters;
  final LoadStatus taxonomyStatus;

  final LoadStatus questionStatus;
  final LoadStatus reviewStatus;
  final List<Question> questions;
  final int currentIndex;

  /// questionId → recorded answer for the active session.
  final Map<String, UserAnswer> answers;
  final AnswerFeedback? feedback;

  final bool sessionStarted;
  final StudySession? activeSession;
  final StudySession? reviewSession;
  final List<StudySession> history;

  final bool isOnline;
  final int queuedCount;
  final String? errorMessage;

  /// Set when a session ends; drives the SessionResultModal. Null while in play.
  final SessionSummary? resultSummary;

  /// Whether the post-session NPS survey has already been shown/handled this
  /// session — prevents showing it more than once.
  final bool npsHandled;

  /// Whether the server says this user is due an NPS survey (set from
  /// `checkNpsEligibility` when a session ends). The survey only shows when true.
  final bool npsEligible;

  /// True while [SessionFinished] is closing the server session (and checking
  /// NPS eligibility) — drives the loader on the End button.
  final bool finishing;

  /// Positive terminal state: the chapter is tapped out and the student has
  /// answered everything available. Drives the mastery celebration UI (not an
  /// error). Mirrors React's `mastered` status from useQuestionPolling.
  final bool mastered;

  Question? get currentQuestion =>
      currentIndex >= 0 && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  bool get hasAnsweredCurrent =>
      currentQuestion != null && answers.containsKey(currentQuestion!.id);

  int get correctCount => answers.values.where((a) => a.isCorrect).length;
  int get answeredCount => answers.length;

  /// Trailing run of consecutive correct answers (most-recent first), mirroring
  /// React's `currentStreak`. Walks answers in the order they were submitted.
  int get currentStreak {
    final ordered = answers.values.toList()
      ..sort((a, b) => a.answeredAtMillis.compareTo(b.answeredAtMillis));
    var streak = 0;
    for (var i = ordered.length - 1; i >= 0; i--) {
      if (ordered[i].isCorrect) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  SessionState copyWith({
    SessionPanel? panel,
    StudyConfig? config,
    List<ClassOption>? classes,
    List<SubjectOption>? subjects,
    List<ChapterOption>? chapters,
    LoadStatus? taxonomyStatus,
    LoadStatus? questionStatus,
    LoadStatus? reviewStatus,
    List<Question>? questions,
    int? currentIndex,
    Map<String, UserAnswer>? answers,
    AnswerFeedback? feedback,
    bool clearFeedback = false,
    bool? sessionStarted,
    StudySession? activeSession,
    StudySession? reviewSession,
    List<StudySession>? history,
    bool? isOnline,
    int? queuedCount,
    String? errorMessage,
    bool clearError = false,
    SessionSummary? resultSummary,
    bool clearResultSummary = false,
    bool? npsHandled,
    bool? npsEligible,
    bool? finishing,
    bool? mastered,
  }) {
    return SessionState(
      panel: panel ?? this.panel,
      config: config ?? this.config,
      classes: classes ?? this.classes,
      subjects: subjects ?? this.subjects,
      chapters: chapters ?? this.chapters,
      taxonomyStatus: taxonomyStatus ?? this.taxonomyStatus,
      questionStatus: questionStatus ?? this.questionStatus,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      sessionStarted: sessionStarted ?? this.sessionStarted,
      activeSession: activeSession ?? this.activeSession,
      reviewSession: reviewSession ?? this.reviewSession,
      history: history ?? this.history,
      isOnline: isOnline ?? this.isOnline,
      queuedCount: queuedCount ?? this.queuedCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resultSummary:
          clearResultSummary ? null : (resultSummary ?? this.resultSummary),
      npsHandled: npsHandled ?? this.npsHandled,
      npsEligible: npsEligible ?? this.npsEligible,
      finishing: finishing ?? this.finishing,
      mastered: mastered ?? this.mastered,
    );
  }

  @override
  List<Object?> get props => [
        panel,
        config,
        classes,
        subjects,
        chapters,
        taxonomyStatus,
        questionStatus,
        reviewStatus,
        questions,
        currentIndex,
        answers,
        feedback,
        sessionStarted,
        activeSession,
        reviewSession,
        history,
        isOnline,
        queuedCount,
        errorMessage,
        resultSummary,
        npsHandled,
        npsEligible,
        finishing,
        mastered,
      ];
}
