part of 'session_bloc.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();
  @override
  List<Object?> get props => [];
}

/// Load persisted history + wire connectivity-driven sync on screen open.
class SessionInitialised extends SessionEvent {
  const SessionInitialised();
}

// --- Configuration funnel ---------------------------------------------------
class ClassesRequested extends SessionEvent {
  const ClassesRequested();
}

class ClassSelected extends SessionEvent {
  const ClassSelected(this.option);
  final ClassOption option;
  @override
  List<Object?> get props => [option];
}

class SubjectSelected extends SessionEvent {
  const SubjectSelected(this.option);
  final SubjectOption option;
  @override
  List<Object?> get props => [option];
}

class ChapterSelected extends SessionEvent {
  const ChapterSelected(this.option);
  final ChapterOption option;
  @override
  List<Object?> get props => [option];
}

class QuestionTypeSelected extends SessionEvent {
  const QuestionTypeSelected(this.type);
  final QuestionType type;
  @override
  List<Object?> get props => [type];
}

class DifficultySelected extends SessionEvent {
  const DifficultySelected(this.difficulty);
  final Difficulty difficulty;
  @override
  List<Object?> get props => [difficulty];
}

// --- Practice ---------------------------------------------------------------
class PracticeStarted extends SessionEvent {
  const PracticeStarted({this.userId = ''});

  /// Logged-in user's id, needed to create the server-side session whose
  /// ObjectId the question-batch endpoint requires.
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class AnswerSubmitted extends SessionEvent {
  const AnswerSubmitted(this.answer);
  final String answer;
  @override
  List<Object?> get props => [answer];
}

class NextQuestionRequested extends SessionEvent {
  const NextQuestionRequested();
}

class SessionFinished extends SessionEvent {
  const SessionFinished({this.userId = ''});

  /// Used to ask the server whether the post-session NPS survey is due.
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Dismisses the end-of-session result modal and returns to the config panel.
class ResultModalDismissed extends SessionEvent {
  const ResultModalDismissed();
}

/// Submits the post-session NPS survey (0–10 + optional comment).
class NpsSubmitted extends SessionEvent {
  const NpsSubmitted({
    required this.userId,
    required this.score,
    this.comment,
  });
  final String userId;
  final int score;
  final String? comment;
  @override
  List<Object?> get props => [userId, score, comment];
}

/// Marks the NPS survey as handled without submitting (user dismissed it).
class NpsDismissed extends SessionEvent {
  const NpsDismissed();
}

// --- History / review -------------------------------------------------------
class SessionReviewOpened extends SessionEvent {
  const SessionReviewOpened(this.sessionId);
  final String sessionId;
  @override
  List<Object?> get props => [sessionId];
}

class SessionDeleted extends SessionEvent {
  const SessionDeleted(this.sessionId);
  final String sessionId;
  @override
  List<Object?> get props => [sessionId];
}

class BackToConfigRequested extends SessionEvent {
  const BackToConfigRequested();
}

// --- Offline sync -----------------------------------------------------------
class ConnectivityChanged extends SessionEvent {
  const ConnectivityChanged(this.isOnline);
  final bool isOnline;
  @override
  List<Object?> get props => [isOnline];
}
