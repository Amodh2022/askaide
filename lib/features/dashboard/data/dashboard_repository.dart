import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';
import 'dashboard_models.dart';

/// Remote data source + repository for dashboard stats and progress. Reads the
/// `/progress/user/:id` and `/streaks/:id` endpoints and merges them.
class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, DashboardData>> loadDashboard(String userId) =>
      guardEither(() async {
        final progressRes = await _dio.get(Endpoints.userProgress(userId));
        final p = progressRes.dataMap();
        final subjects = p
            .listAt(['subjectsProgress', 'subjects'])
            .whereType<Map>()
            .map(SubjectProgress.fromJson)
            .toList();

        // Headline accuracy/volume from `overallAccuracy` when present.
        final acc = p['overallAccuracy'] is Map ? p['overallAccuracy'] as Map : const {};
        final today = p['todayStats'] is Map ? p['todayStats'] as Map : const {};
        final lastCh = p['lastStudiedChapter'] is Map ? p['lastStudiedChapter'] as Map : null;
        final weekly = _parseWeekly(p['weeklyActivity']);

        var data = DashboardData(
          overallMastery: _frac(p.dbl(['overallMastery', 'mastery'])),
          currentStreak: p.intval(['streakDays', 'currentStreak']),
          badges: p.listAt(['badges']).map((e) => e.toString()).toList(),
          subjects: subjects,
          totalCount: acc.intval(['totalCount']),
          accuracyExact: acc.dbl(['accuracyPercent']),
          todayQuestions: today.intval(['questionsAnswered']),
          todayAccuracy: today.dbl(['accuracy']),
          todayTimeSpentSec: today.intval(['timeSpent']),
          weekly: weekly,
          lastStudied: lastCh == null
              ? null
              : LastStudied(
                  chapter: lastCh.str(['chapter', 'chapterName']),
                  subject: lastCh.str(['subject', 'subjectName']),
                ),
        );

        // Streak endpoint is best-effort; ignore failures.
        try {
          final streakRes = await _dio.get(Endpoints.streak(userId));
          final s = streakRes.dataMap();
          data = data.copyWith(
            currentStreak: s.intval(['currentStreak'], data.currentStreak),
            longestStreak: s.intval(['longestStreak']),
            freezesRemaining: s.intval(['freezesRemaining', 'freezes']),
            practiceDates: s
                .listAt(['practiceDates'])
                .map((e) => DateTime.tryParse(e.toString()))
                .whereType<DateTime>()
                .toList(),
          );
        } catch (_) {}

        // The remaining sources are all best-effort — a 404 on any one of them
        // must not blank the whole dashboard.
        data = data.copyWith(challenge: await _maybe(
            () async => DailyChallengeInfo.fromJson(
                (await _dio.get(Endpoints.dailyChallenge(userId))).dataMap())));
        data = data.copyWith(goal: await _maybe(
            () async => DailyGoalInfo.fromJson((await _dio.get(Endpoints.goals)).dataMap())));
        data = data.copyWith(continueSession: await _maybe(
            () async => ContinueSessionInfo.fromJson(
                (await _dio.get(Endpoints.lastIncompleteSession(userId))).dataMap())));
        data = data.copyWith(referral: await _maybe(
            () async => ReferralSummary.fromJson(
                (await _dio.get(Endpoints.referralMyCode)).dataMap())));
        data = data.copyWith(leaderboard: await _maybe(() async {
              final res = await _dio.get(Endpoints.leaderboard,
                  queryParameters: {'limit': 10});
              return res
                  .dataList(['leaderboard', 'entries'])
                  .whereType<Map>()
                  .map((e) => LeaderboardEntry.fromJson(e, userId))
                  .toList();
            }) ??
            const []);

        return data;
      });

  /// Runs [fn], returning its value or null if it throws (best-effort fetch).
  Future<T?> _maybe<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  /// Parses `weeklyActivity.dates[]` into 7 [DayActivity] bars (most recent last).
  List<DayActivity> _parseWeekly(dynamic raw) {
    final map = raw is Map ? raw : const {};
    final dates = map.listAt(['dates']);
    if (dates.isEmpty) return const [];
    const wk = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    return dates.whereType<Map>().map((d) {
      final dateStr = d.str(['date']);
      final dt = DateTime.tryParse(dateStr);
      final label = dt != null ? wk[dt.weekday - 1] : '';
      return DayActivity(
        label: label,
        questions: d.intval(['questionsAnswered', 'questions']),
        accuracy: d.dbl(['accuracy']),
        isToday: dateStr == todayStr,
      );
    }).toList();
  }

  Future<Either<Failure, List<TopicProgressItem>>> loadTopicProgress(
          String userId, String subjectId) =>
      guardEither(() async {
        final res =
            await _dio.get(Endpoints.topicProgress(userId, subjectId));
        return res
            .dataList(['topics'])
            .whereType<Map>()
            .map(TopicProgressItem.fromJson)
            .toList();
      });
}

/// Normalise a mastery value to a 0..1 fraction (backend may send 0..100).
double _frac(double v) => v > 1 ? v / 100 : v;
