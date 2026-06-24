import 'package:equatable/equatable.dart';

import '../../../core/network/api_helpers.dart';

/// Mastery for a single subject, parsed from `subjectsProgress[]`.
class SubjectProgress extends Equatable {
  const SubjectProgress({
    required this.subjectId,
    required this.name,
    required this.mastery,
    required this.coverage,
    required this.questionsAttempted,
    required this.correctAnswers,
  });

  final String subjectId;
  final String name;
  final double mastery; // 0..1
  final double coverage; // 0..1
  final int questionsAttempted;
  final int correctAnswers;

  factory SubjectProgress.fromJson(Map<dynamic, dynamic> j) => SubjectProgress(
        subjectId: j.str(['subjectId', '_id', 'id']),
        name: j.str(['subjectName', 'name'], 'Subject'),
        mastery: _frac(j.dbl(['mastery', 'masteryPercent', 'accuracy'])),
        coverage: _frac(j.dbl(['coverage'])),
        questionsAttempted: j.intval(['questionsAttempted', 'totalQuestions', 'attempted']),
        correctAnswers: j.intval(['correctAnswers', 'correct']),
      );

  static double _frac(double v) => v > 1 ? v / 100 : v;

  @override
  List<Object?> get props => [subjectId, name, mastery, coverage, questionsAttempted, correctAnswers];
}

/// One day's bar in the weekly-activity chart.
class DayActivity extends Equatable {
  const DayActivity({
    required this.label,
    required this.questions,
    required this.accuracy,
    required this.isToday,
  });
  final String label; // Mon, Tue…
  final int questions;
  final double accuracy; // 0..100
  final bool isToday;

  @override
  List<Object?> get props => [label, questions, accuracy, isToday];
}

/// A row in the class leaderboard.
class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.name,
    required this.totalQuestions,
    required this.accuracy,
    required this.isCurrentUser,
  });
  final String name;
  final int totalQuestions;
  final double? accuracy; // 0..100
  final bool isCurrentUser;

  factory LeaderboardEntry.fromJson(Map<dynamic, dynamic> j, String currentUserId) {
    final id = j.str(['userId', '_id', 'id']);
    return LeaderboardEntry(
      name: j.str(['name', 'userName'], 'Student'),
      totalQuestions: j.intval(['totalQuestions', 'score']),
      accuracy: j['accuracy'] != null ? j.dbl(['accuracy']) : null,
      isCurrentUser: currentUserId.isNotEmpty && id == currentUserId,
    );
  }

  @override
  List<Object?> get props => [name, totalQuestions, accuracy, isCurrentUser];
}

/// Today's auto-generated daily challenge.
class DailyChallengeInfo extends Equatable {
  const DailyChallengeInfo({
    required this.topicName,
    required this.subjectName,
    required this.difficulty,
    required this.totalQuestions,
    required this.score,
    required this.completed,
    this.completedAt,
  });
  final String topicName;
  final String subjectName;
  final String difficulty;
  final int totalQuestions;
  final int score;
  final bool completed;
  final DateTime? completedAt;

  factory DailyChallengeInfo.fromJson(Map<dynamic, dynamic> j) => DailyChallengeInfo(
        topicName: j.str(['topicName'], 'Practice'),
        subjectName: j.str(['subjectName'], ''),
        difficulty: j.str(['difficulty'], 'medium'),
        totalQuestions: j.intval(['totalQuestions'], 5),
        score: j.intval(['score']),
        completed: j.boolean(['completed']),
        completedAt: DateTime.tryParse(j.str(['completedAt'])),
      );

  @override
  List<Object?> get props =>
      [topicName, subjectName, difficulty, totalQuestions, score, completed, completedAt];
}

/// The user's daily-goal progress.
class DailyGoalInfo extends Equatable {
  const DailyGoalInfo({
    required this.currentProgress,
    required this.dailyGoal,
    required this.remaining,
    required this.percentComplete,
    required this.completed,
  });
  final int currentProgress;
  final int dailyGoal;
  final int remaining;
  final double percentComplete; // 0..100
  final bool completed;

  factory DailyGoalInfo.fromJson(Map<dynamic, dynamic> j) {
    final goal = j.intval(['dailyGoal'], 20);
    final progress = j.intval(['currentProgress']);
    final remaining = j['remaining'] != null ? j.intval(['remaining']) : (goal - progress);
    final pct = j['percentComplete'] != null
        ? j.dbl(['percentComplete'])
        : (goal == 0 ? 0.0 : (progress / goal * 100));
    return DailyGoalInfo(
      currentProgress: progress,
      dailyGoal: goal,
      remaining: remaining < 0 ? 0 : remaining,
      percentComplete: pct.clamp(0, 100),
      completed: j['completed'] != null ? j.boolean(['completed']) : progress >= goal,
    );
  }

  @override
  List<Object?> get props =>
      [currentProgress, dailyGoal, remaining, percentComplete, completed];
}

/// The last unfinished study session, for the "Continue your session" banner.
class ContinueSessionInfo extends Equatable {
  const ContinueSessionInfo({
    required this.sessionId,
    required this.chapter,
    required this.answeredCount,
    this.startedAt,
  });
  final String sessionId;
  final String chapter;
  final int answeredCount;
  final DateTime? startedAt;

  factory ContinueSessionInfo.fromJson(Map<dynamic, dynamic> j) => ContinueSessionInfo(
        sessionId: j.str(['_id', 'sessionId', 'id']),
        chapter: j.str(['chapter', 'chapterName'], 'Your session'),
        answeredCount: j.intval(['answeredCount', 'questionsAnswered']),
        startedAt: DateTime.tryParse(j.str(['startedAt', 'createdAt'])),
      );

  @override
  List<Object?> get props => [sessionId, chapter, answeredCount, startedAt];
}

/// Referral summary for the dashboard invite card.
class ReferralSummary extends Equatable {
  const ReferralSummary({
    required this.code,
    required this.link,
    required this.totalReferrals,
  });
  final String code;
  final String link;
  final int totalReferrals;

  factory ReferralSummary.fromJson(Map<dynamic, dynamic> j) => ReferralSummary(
        code: j.str(['referralCode', 'code']),
        link: j.str(['referralLink', 'link']),
        totalReferrals: j.intval(['totalReferrals']),
      );

  @override
  List<Object?> get props => [code, link, totalReferrals];
}

/// The chapter/subject of the user's most recent session.
class LastStudied extends Equatable {
  const LastStudied({required this.chapter, required this.subject});
  final String chapter;
  final String subject;
  @override
  List<Object?> get props => [chapter, subject];
}

/// Aggregated dashboard data combining the progress, streak, challenge, goal,
/// leaderboard, last-session and referral endpoints.
class DashboardData extends Equatable {
  const DashboardData({
    this.overallMastery = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.freezesRemaining = 0,
    this.badges = const [],
    this.subjects = const [],
    this.totalCount = 0,
    this.accuracyExact = 0,
    this.todayQuestions = 0,
    this.todayAccuracy = 0,
    this.todayTimeSpentSec = 0,
    this.weekly = const [],
    this.practiceDates = const [],
    this.lastStudied,
    this.leaderboard = const [],
    this.challenge,
    this.goal,
    this.continueSession,
    this.referral,
  });

  final double overallMastery; // 0..1
  final int currentStreak;
  final int longestStreak;
  final int freezesRemaining;
  final List<String> badges;
  final List<SubjectProgress> subjects;

  // Headline accuracy/volume, taken from `overallAccuracy` when present.
  final int totalCount;
  final double accuracyExact; // 0..100

  // Today's activity
  final int todayQuestions;
  final double todayAccuracy; // 0..100
  final int todayTimeSpentSec;

  final List<DayActivity> weekly;
  final List<DateTime> practiceDates;
  final LastStudied? lastStudied;
  final List<LeaderboardEntry> leaderboard;
  final DailyChallengeInfo? challenge;
  final DailyGoalInfo? goal;
  final ContinueSessionInfo? continueSession;
  final ReferralSummary? referral;

  int get totalQuestions =>
      totalCount > 0 ? totalCount : subjects.fold(0, (sum, s) => sum + s.questionsAttempted);
  int get subjectCount => subjects.length;
  int get accuracyPercent =>
      accuracyExact > 0 ? accuracyExact.round() : (overallMastery * 100).round();

  DashboardData copyWith({
    double? overallMastery,
    int? currentStreak,
    int? longestStreak,
    int? freezesRemaining,
    List<String>? badges,
    List<SubjectProgress>? subjects,
    int? totalCount,
    double? accuracyExact,
    int? todayQuestions,
    double? todayAccuracy,
    int? todayTimeSpentSec,
    List<DayActivity>? weekly,
    List<DateTime>? practiceDates,
    LastStudied? lastStudied,
    List<LeaderboardEntry>? leaderboard,
    DailyChallengeInfo? challenge,
    DailyGoalInfo? goal,
    ContinueSessionInfo? continueSession,
    ReferralSummary? referral,
  }) =>
      DashboardData(
        overallMastery: overallMastery ?? this.overallMastery,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        freezesRemaining: freezesRemaining ?? this.freezesRemaining,
        badges: badges ?? this.badges,
        subjects: subjects ?? this.subjects,
        totalCount: totalCount ?? this.totalCount,
        accuracyExact: accuracyExact ?? this.accuracyExact,
        todayQuestions: todayQuestions ?? this.todayQuestions,
        todayAccuracy: todayAccuracy ?? this.todayAccuracy,
        todayTimeSpentSec: todayTimeSpentSec ?? this.todayTimeSpentSec,
        weekly: weekly ?? this.weekly,
        practiceDates: practiceDates ?? this.practiceDates,
        lastStudied: lastStudied ?? this.lastStudied,
        leaderboard: leaderboard ?? this.leaderboard,
        challenge: challenge ?? this.challenge,
        goal: goal ?? this.goal,
        continueSession: continueSession ?? this.continueSession,
        referral: referral ?? this.referral,
      );

  @override
  List<Object?> get props => [
        overallMastery,
        currentStreak,
        longestStreak,
        freezesRemaining,
        badges,
        subjects,
        totalCount,
        accuracyExact,
        todayQuestions,
        todayAccuracy,
        todayTimeSpentSec,
        weekly,
        practiceDates,
        lastStudied,
        leaderboard,
        challenge,
        goal,
        continueSession,
        referral,
      ];
}

/// A topic row in the Progress screen's chapter/topic breakdown.
class TopicProgressItem extends Equatable {
  const TopicProgressItem({
    required this.topicId,
    required this.name,
    required this.mastery,
    required this.questionsAttempted,
  });

  final String topicId;
  final String name;
  final double mastery; // 0..1
  final int questionsAttempted;

  factory TopicProgressItem.fromJson(Map<dynamic, dynamic> j) => TopicProgressItem(
        topicId: j.str(['topicId', '_id', 'id']),
        name: j.str(['name', 'topicName'], 'Topic'),
        mastery: SubjectProgress._frac(j.dbl(['mastery', 'accuracy'])),
        questionsAttempted: j.intval(['questionsAttempted', 'attempted']),
      );

  @override
  List<Object?> get props => [topicId, name, mastery, questionsAttempted];
}
