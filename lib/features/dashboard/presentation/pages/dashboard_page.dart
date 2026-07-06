import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/state_visuals.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/dashboard_models.dart';
import '../cubit/continue_banner_cubit.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/show_all_cubit.dart';

part 'dashboard_page_parts/header.dart';
part 'dashboard_page_parts/engagement_cards.dart';
part 'dashboard_page_parts/activity_cards.dart';
part 'dashboard_page_parts/referral_card.dart';
part 'dashboard_page_parts/achievements_leaderboard.dart';
part 'dashboard_page_parts/mastery.dart';
part 'dashboard_page_parts/shared_cards.dart';

/// `/dashboard` — the student overview. Mirrors the frontend Dashboard: hero
/// greeting with the full streak display + share, continue-session banner,
/// daily challenge, quick-start CTA, stats, today's activity / continue-learning
/// / weekly chart / practice calendar / daily goal / referral cards, quick
/// actions, achievements + leaderboard, and mastery overview — all wired to
/// live data and styled to match the React "Quiet Scholar" components.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) {
        final cubit = sl<DashboardCubit>();
        final userId = context.read<ProfileCubit>().state.user?.id ?? '';
        cubit.load(userId);
        return cubit;
      },
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  ({String label, String motivation, String timeOfDay}) _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) {
      return (label: 'GOOD MORNING', motivation: 'Start your morning strong.', timeOfDay: 'morning');
    }
    if (h < 17) {
      return (label: 'GOOD AFTERNOON', motivation: 'Keep the momentum going.', timeOfDay: 'afternoon');
    }
    return (label: 'GOOD EVENING', motivation: 'Evening practice makes perfect.', timeOfDay: 'evening');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = context.watch<ProfileCubit>().state;
    final firstName = profile.user?.firstName ?? 'Learner';
    final userId = profile.user?.id ?? '';
    final dashState = context.watch<DashboardCubit>().state;
    final data = dashState.data;
    // First load (no data yet): show a loader, mirroring the frontend which
    // gates the stats/cards behind `!loading`.
    final loading = dashState.status == DashboardStatus.initial ||
        dashState.status == DashboardStatus.loading;
    final g = _greeting();

    // Practiced today is derived: any questions answered today, or today is in
    // the streak's practiceDates set.
    final today = DateTime.now();
    final practicedToday = data.todayQuestions > 0 ||
        data.practiceDates.any((d) =>
            d.year == today.year && d.month == today.month && d.day == today.day);

    return BlocListener<ProfileCubit, ProfileState>(
      // The profile loads asynchronously; the dashboard is first built before
      // the user id is known, so (re)load stats once it arrives. Mirrors the
      // frontend Dashboard's `useEffect(..., [userId])`.
      listenWhen: (p, n) => p.user?.id != n.user?.id,
      listener: (context, profile) {
        final id = profile.user?.id ?? '';
        if (id.isNotEmpty) context.read<DashboardCubit>().load(id);
      },
      child: RefreshIndicator(
        onRefresh: () {
          final id = context.read<ProfileCubit>().state.user?.id ?? '';
          if (id.isNotEmpty) context.read<DashboardCubit>().load(id);
          return Future.value();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero greeting ──
                Text(g.label, style: AppTypography.sectionLabel(c.textMuted)),
                const SizedBox(height: 6),
                Text('Good ${g.timeOfDay}, $firstName!',
                    style: AppTypography.h1(c.textPrimary).copyWith(fontSize: 30)),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  spacing: 10,
                  children: [
                    Text(g.motivation, style: AppTypography.bodyMedium(c.textMuted)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _StreakDisplay(
                              data: data,
                              practicedToday: practicedToday,
                              loading: loading,
                            ),
                          ),
                        ),
                        if (userId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _IconButton(
                            icon: LucideIcons.share2,
                            tooltip: 'Share your profile',
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: '/student/$userId'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile link copied!')));
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Loss-aversion nudge when the streak is at risk.
                if (!practicedToday && data.currentStreak > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8722A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE8722A).withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      '⚡ PRACTICE TODAY TO SAVE YOUR ${data.currentStreak}-DAY STREAK!',
                      textAlign: TextAlign.center,
                      style: AppTypography.mono(const Color(0xFFE8722A), size: 9)
                          .copyWith(letterSpacing: 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (loading)
                  const _DashboardSkeleton()
                else ...[
                  // ── Continue session banner ──
                  if (data.continueSession != null) ...[
                    _ContinueBanner(session: data.continueSession!),
                    const SizedBox(height: 16),
                  ],

                  // ── Daily challenge ──
                  if (data.challenge != null) ...[
                    _DailyChallengeCard(challenge: data.challenge!),
                    const SizedBox(height: 16),
                  ],

                  // ── Quick start CTA ──
                  FilledButton.icon(
                    onPressed: () => context.go(RoutePaths.study),
                    icon: const Icon(LucideIcons.play, size: 15),
                    label: const Text('Start Practicing  →'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Stats overview ──
                  LayoutBuilder(builder: (context, cons) {
                    final cols = cons.maxWidth > 560 ? 3 : 1;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: cols == 3 ? 2.4 : 4.4,
                      children: [
                        _StatCard(animateTo: data.totalQuestions, label: 'QUESTIONS'),
                        _StatCard(
                            value: data.totalQuestions == 0 ? '—' : '${data.accuracyPercent}%',
                            animateTo: data.totalQuestions == 0 ? null : data.accuracyPercent,
                            suffix: '%',
                            label: 'ACCURACY'),
                        _StatCard(animateTo: data.subjectCount, label: 'SUBJECTS'),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),

                  // ── Activity / continue / weekly / calendar / goal / referral grid ──
                  _CardGrid(children: [
                    _TodayActivityCard(data: data),
                    _ContinueLearningCard(lastStudied: data.lastStudied),
                    _WeeklyActivityChart(weekly: data.weekly),
                    _PracticeCalendarCard(practiceDates: data.practiceDates),
                    if (data.goal != null) _DailyGoalCard(goal: data.goal!),
                    _ReferralCard(referral: data.referral),
                  ]),
                  const SizedBox(height: 28),

                  // ── Quick actions ──
                  Text('QUICK ACTIONS', style: AppTypography.sectionLabel(c.textMuted)),
                  const SizedBox(height: 10),
                  _CardGrid(minWidth: 200, children: [
                    _ActionCard(
                      icon: LucideIcons.bookOpen,
                      title: 'Quick Practice',
                      subtitle: '15-minute session',
                      accent: true,
                      onTap: () => context.go(RoutePaths.study),
                    ),
                    _ActionCard(
                      icon: LucideIcons.zap,
                      title: 'Take a Quiz',
                      subtitle: 'Test your skills',
                      onTap: () => context.go(RoutePaths.quizzes),
                    ),
                    _ActionCard(
                      icon: LucideIcons.trendingUp,
                      title: 'Review Progress',
                      subtitle: 'Track your journey',
                      onTap: () => context.go(RoutePaths.progress),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Achievements + leaderboard ──
                  _CardGrid(children: [
                    _AchievementsCard(earned: data.badges),
                    _LeaderboardCard(entries: data.leaderboard),
                  ]),

                  // ── Mastery overview ──
                  if (data.subjects.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _MasteryOverview(data: data),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
