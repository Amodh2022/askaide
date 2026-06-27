import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

        // The frontend's WeeklyActivityChart prefers `weeklyActivity.dates` but
        // falls back to computing the 7-day grid from the user's sessions. Fetch
        // those (best-effort) so we can do the same instead of showing an empty
        // card when the progress payload lacks weeklyActivity.
        final sessions = await _maybe(() async {
              final res = await _dio.get(Endpoints.sessionsByUser(userId));
              return res.dataList().whereType<Map>().toList();
            }) ??
            const <Map>[];
        final weekly = _buildWeekly(p['weeklyActivity'], sessions);

        var data = DashboardData(
          overallMastery: _frac(p.dbl(['overallMastery', 'mastery'])),
          currentStreak: p.intval(['currentStreak', 'streakDays']),
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

        // Streak endpoint is the source of truth (the frontend's StreakDisplay
        // reads it via fetchStreak); best-effort, a failure here must not blank
        // the dashboard. The payload is sometimes nested under a `streak`
        // object, so check both levels.
        final s = await _maybe(() async {
          final streakRes = await _dio.get(Endpoints.streak(userId));
          final outer = streakRes.dataMap();
          return outer['streak'] is Map
              ? Map<String, dynamic>.from(outer['streak'] as Map)
              : outer;
        });
        if (s != null) {
          // Freezes can be a flat count or `streakFreezes: { available }`.
          final freezesObj = s['streakFreezes'] is Map
              ? Map<String, dynamic>.from(s['streakFreezes'] as Map)
              : const {};
          data = data.copyWith(
            currentStreak:
                s.intval(['currentStreak', 'streak', 'streakDays'], data.currentStreak),
            longestStreak: s.intval(['longestStreak', 'bestStreak']),
            freezesRemaining: freezesObj.isNotEmpty
                ? freezesObj.intval(['available'])
                : s.intval(['freezesRemaining', 'freezes']),
            practiceDates: s
                .listAt(['practiceDates'])
                .map((e) => DateTime.tryParse(e.toString()))
                .whereType<DateTime>()
                .toList(),
          );
        }

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
                  .dataList(['leaderboard', 'entries', 'rankings', 'users', 'topUsers'])
                  .whereType<Map>()
                  .map((e) => LeaderboardEntry.fromJson(e, userId))
                  .toList();
            }) ??
            const []);

        return data;
      });

  /// Runs [fn], returning its value or null if it throws (best-effort fetch).
  /// Failures are intentionally non-fatal — an optional sub-resource (streak,
  /// goal, leaderboard…) must not blank the whole dashboard — but they are
  /// logged in debug builds so a swallowed error is still observable.
  Future<T?> _maybe<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      if (kDebugMode) {
        developer.log('best-effort dashboard fetch failed',
            name: 'DashboardRepository', error: e, stackTrace: st);
      }
      return null;
    }
  }

  /// Builds the last-7-days activity grid (oldest → newest), mirroring the
  /// frontend WeeklyActivityChart: prefer `weeklyActivity.dates[]`, otherwise
  /// aggregate the user's sessions by day. Always returns 7 bars so the card
  /// shows the grid (zeros included) rather than an empty state.
  List<DayActivity> _buildWeekly(dynamic raw, List<Map> sessions) {
    const wk = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final map = raw is Map ? raw : const {};

    // Index pre-computed stats by `YYYY-MM-DD` when present.
    final byDate = <String, Map>{};
    for (final d in map.listAt(['dates']).whereType<Map>()) {
      final ds = d.str(['date']);
      if (ds.isNotEmpty) byDate[ds.split('T').first] = d;
    }

    // Index session question counts / correct totals by day for the fallback.
    final sessQ = <String, int>{};
    final sessCorrect = <String, int>{};
    for (final s in sessions) {
      final ds = s.str(['createdAt', 'startTime', 'timestamp']);
      final key = DateTime.tryParse(ds)?.toLocal();
      if (key == null) continue;
      final k = _dayKey(key);
      sessQ[k] = (sessQ[k] ?? 0) + s.intval(['totalquestions', 'totalQuestions']);
      sessCorrect[k] = (sessCorrect[k] ?? 0) + s.intval(['score']);
    }

    final today = DateTime.now();
    final todayKey = _dayKey(today);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final key = _dayKey(day);
      final stat = byDate[key];
      int questions;
      double accuracy;
      if (stat != null) {
        questions = stat.intval(['questionsAnswered', 'questions']);
        accuracy = stat.dbl(['accuracy']);
      } else {
        questions = sessQ[key] ?? 0;
        final correct = sessCorrect[key] ?? 0;
        accuracy = questions > 0 ? (correct / questions) * 100 : 0;
      }
      return DayActivity(
        label: wk[day.weekday - 1],
        questions: questions,
        accuracy: accuracy,
        isToday: key == todayKey,
      );
    });
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
