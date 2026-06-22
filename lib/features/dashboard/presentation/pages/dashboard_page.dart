import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/dashboard_models.dart';
import '../cubit/dashboard_cubit.dart';

/// `/dashboard` — the student overview. Mirrors the frontend Dashboard: hero
/// greeting with streak + share, continue-session banner, daily challenge,
/// quick-start CTA, stats, today's activity / continue-learning / weekly chart /
/// streak calendar / daily goal / referral cards, quick actions, badges +
/// leaderboard, and mastery overview — all wired to live data.
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
    final data = context.watch<DashboardCubit>().state.data;
    final g = _greeting();

    return SingleChildScrollView(
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
                runSpacing: 10,
                spacing: 10,
                children: [
                  Text(g.motivation, style: AppTypography.bodyMedium(c.textMuted)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StreakChip(streak: data.currentStreak),
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
              const SizedBox(height: 24),

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

              // ── Activity / continue / weekly / streak / goal / referral grid ──
              _CardGrid(children: [
                _TodayActivityCard(data: data),
                _ContinueLearningCard(lastStudied: data.lastStudied),
                _WeeklyActivityChart(weekly: data.weekly),
                _StreakCalendarCard(practiceDates: data.practiceDates, streak: data.currentStreak),
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

              // ── Badges + leaderboard ──
              _CardGrid(children: [
                _BadgesCard(badges: data.badges),
                _LeaderboardCard(entries: data.leaderboard),
              ]),

              // ── Mastery overview ──
              if (data.subjects.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Mastery by subject', style: AppTypography.h3(c.textPrimary)),
                const SizedBox(height: 12),
                _MasteryChart(data: data),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A responsive grid of equal-height cards (auto-fit, min [minWidth] wide).
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children, this.minWidth = 280});
  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final cols = (cons.maxWidth / minWidth).floor().clamp(1, children.length).toInt();
      const gap = 12.0;
      final width = (cons.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: cols == 1 ? cons.maxWidth : width, child: child),
        ],
      );
    });
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.accentLight,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, size: 14, color: c.accentSecondary),
          const SizedBox(width: 6),
          Text('$streak', style: AppTypography.mono(c.textPrimary, size: 13)),
          const SizedBox(width: 4),
          Text('day streak', style: AppTypography.bodySmall(c.textMuted)),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: c.textMuted),
        ),
      ),
    );
  }
}

/// Accent banner inviting the user to resume their unfinished session.
class _ContinueBanner extends StatelessWidget {
  const _ContinueBanner({required this.session});
  final ContinueSessionInfo session;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(LucideIcons.bookOpen, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Continue your session',
                    style: AppTypography.h4(Colors.white).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${session.chapter} · ${session.answeredCount} answered · ${_timeAgo(session.startedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => context.go(RoutePaths.study),
            icon: const Icon(LucideIcons.play, size: 14),
            label: const Text('Resume'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: c.accent,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime? d) {
    if (d == null) return 'recently';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Today's daily challenge, focused on the user's weakest topic.
class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});
  final DailyChallengeInfo challenge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = challenge.completed;
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: done
                  ? null
                  : LinearGradient(colors: [c.accent, c.accentSecondary]),
              color: done ? c.accent : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: done ? c.accent : c.accentSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(done ? LucideIcons.circleCheckBig : LucideIcons.zap,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Challenge',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                          Text(done ? 'Completed! 🎉' : 'Focus on your weak spots',
                              style: AppTypography.bodySmall(c.textSecondary)),
                        ],
                      ),
                    ),
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.successBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('${challenge.score}/${challenge.totalQuestions}',
                            style: AppTypography.mono(c.success, size: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.topicName,
                          style: AppTypography.labelLarge(c.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        '${challenge.subjectName} • ${challenge.totalQuestions} questions • ${challenge.difficulty}',
                        style: AppTypography.bodySmall(c.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!done) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go(RoutePaths.study),
                      icon: const Icon(LucideIcons.zap, size: 16),
                      label: const Text('Start Challenge  →'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's activity card — questions / accuracy / time in accent tiles.
class _TodayActivityCard extends StatelessWidget {
  const _TodayActivityCard({required this.data});
  final DashboardData data;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tiles = [
      (value: '${data.todayQuestions}', label: 'Questions'),
      (value: '${data.todayAccuracy.round()}%', label: 'Accuracy'),
      (value: '${(data.todayTimeSpentSec / 60).round()}m', label: 'Time'),
    ];
    return _ShellCard(
      icon: LucideIcons.zap,
      title: "Today's Activity",
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(tiles[i].value, style: AppTypography.statNumber(c.textPrimary, size: 18)),
                    const SizedBox(height: 4),
                    Text(tiles[i].label.toUpperCase(),
                        style: AppTypography.mono(c.textMuted, size: 9)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Continue-learning card — resume the last chapter or start fresh.
class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.lastStudied});
  final LastStudied? lastStudied;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => context.go(RoutePaths.study),
      borderRadius: BorderRadius.circular(4),
      child: _ShellCard(
        icon: LucideIcons.play,
        title: 'Continue Learning',
        subtitle: lastStudied != null ? 'Pick up where you left off' : 'Start a new session',
        child: lastStudied != null
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lastStudied!.chapter,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelLarge(c.textPrimary)),
                          Text(lastStudied!.subject, style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.go(RoutePaths.study),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Resume'),
                    ),
                  ],
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    const Text('🚀', style: TextStyle(fontSize: 22)),
                    const SizedBox(height: 10),
                    Text('Ready to start learning? Pick a subject and begin your journey!',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall(c.textMuted)),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => context.go(RoutePaths.study),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Start Practicing →'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// A CSS-style 7-day bar chart of practice activity.
class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({required this.weekly});
  final List<DayActivity> weekly;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxQ = weekly.fold<int>(1, (m, d) => d.questions > m ? d.questions : m);
    return _ShellCard(
      icon: LucideIcons.chartColumn,
      title: 'Weekly Activity',
      child: weekly.isEmpty
          ? Text('No activity yet this week.', style: AppTypography.bodySmall(c.textMuted))
          : SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in weekly)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (d.questions / maxQ * 70).clamp(3, 70).toDouble(),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: d.isToday ? c.accent : c.accentLight,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(d.label,
                              style: AppTypography.mono(
                                  d.isToday ? c.accent : c.textMuted, size: 9)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Streak calendar card (35-day dot grid).
class _StreakCalendarCard extends StatelessWidget {
  const _StreakCalendarCard({required this.practiceDates, required this.streak});
  final List<DateTime> practiceDates;
  final int streak;
  @override
  Widget build(BuildContext context) {
    return _ShellCard(
      icon: LucideIcons.flame,
      title: 'Streak',
      child: _StreakCalendar(practiceDates: practiceDates, streak: streak),
    );
  }
}

/// Daily-goal card with progress bar.
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.goal});
  final DailyGoalInfo goal;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ShellCard(
      icon: LucideIcons.target,
      title: 'Daily Goal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${goal.currentProgress}',
                      style: AppTypography.statNumber(c.textPrimary, size: 24)),
                  Text('/${goal.dailyGoal}', style: AppTypography.bodyMedium(c.textMuted)),
                ],
              ),
              if (goal.completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: c.accentLight, borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.check, size: 10, color: c.accent),
                    const SizedBox(width: 4),
                    Text('DONE', style: AppTypography.mono(c.accent, size: 10)),
                  ]),
                )
              else
                Text('${goal.remaining} left', style: AppTypography.mono(c.textMuted, size: 10)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (goal.percentComplete / 100).clamp(0, 1)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: c.border,
                valueColor: AlwaysStoppedAnimation(c.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Referral invite card linking to the referral page.
class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral});
  final ReferralSummary? referral;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ShellCard(
      icon: LucideIcons.gift,
      title: 'Refer a Friend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (referral != null && referral!.code.isNotEmpty) ...[
            Text('Your referral code', style: AppTypography.bodySmall(c.textMuted)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.accentLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.border),
              ),
              child: Text(referral!.code, style: AppTypography.mono(c.accent, size: 14)),
            ),
            const SizedBox(height: 10),
          ] else
            Text('Invite friends — you both get a streak freeze.',
                style: AppTypography.bodySmall(c.textMuted)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(RoutePaths.referral),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.border),
                shape: const StadiumBorder(),
              ),
              child: Text('Refer & Earn', style: AppTypography.button(c.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badges card (compact achievement chips).
class _BadgesCard extends StatelessWidget {
  const _BadgesCard({required this.badges});
  final List<String> badges;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ShellCard(
      icon: LucideIcons.award,
      title: 'Achievements',
      child: badges.isEmpty
          ? Text('Earn badges by practicing daily.', style: AppTypography.bodySmall(c.textMuted))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in badges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.accentLight,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.award, size: 14, color: c.accent),
                      const SizedBox(width: 6),
                      Text(b, style: AppTypography.bodySmall(c.accent)),
                    ]),
                  ),
              ],
            ),
    );
  }
}

/// Class leaderboard card.
class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries});
  final List<LeaderboardEntry> entries;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ShellCard(
      icon: LucideIcons.trophy,
      title: 'Leaderboard',
      child: entries.isEmpty
          ? Text('No ranking yet — start practicing!',
              style: AppTypography.bodySmall(c.textMuted))
          : Column(
              children: [
                for (var i = 0; i < entries.length && i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text('${i + 1}', style: AppTypography.mono(c.textMuted, size: 12)),
                        ),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: c.accentLight,
                          child: Text(
                            entries[i].name.isNotEmpty ? entries[i].name[0].toUpperCase() : 'U',
                            style: AppTypography.mono(c.accent, size: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entries[i].isCurrentUser
                                ? '${entries[i].name} (You)'
                                : entries[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium(
                                entries[i].isCurrentUser ? c.accent : c.textPrimary),
                          ),
                        ),
                        Text('${entries[i].totalQuestions}',
                            style: AppTypography.mono(c.textMuted, size: 12)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Shared card shell: icon + title (+ optional subtitle) header, then [child].
class _ShellCard extends StatelessWidget {
  const _ShellCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({this.value, required this.label, this.animateTo, this.suffix = ''});
  final String? value;
  final String label;
  final int? animateTo; // when set, count up from 0
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = AppTypography.statNumber(c.textPrimary, size: 22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (animateTo != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: animateTo!.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
            )
          else
            Text(value ?? '—', style: style),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = accent ? Colors.white : c.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent ? c.accent : c.bgCard,
          border: Border.all(color: accent ? c.accent : c.borderSubtle),
          borderRadius: BorderRadius.circular(4),
          boxShadow: AppShadows.card(Theme.of(context).brightness),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4(fg).copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall(accent ? Colors.white70 : c.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent ? Colors.white.withValues(alpha: 0.18) : c.accentLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 18, color: accent ? Colors.white : c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bar chart of mastery (%) per subject, drawn from live progress data.
class _MasteryChart extends StatelessWidget {
  const _MasteryChart({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subjects = data.subjects;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: context.cardDecoration(),
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (v) => FlLine(color: c.borderSubtle, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: AppTypography.mono(c.textMuted, size: 9)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= subjects.length) return const SizedBox.shrink();
                  final name = subjects[i].name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(name.length > 6 ? name.substring(0, 6) : name,
                        style: AppTypography.mono(c.textMuted, size: 9)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < subjects.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (subjects[i].mastery * 100).clamp(0, 100),
                  color: c.accent,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// A 5-week dot grid highlighting practice days (lit cells = practiced).
class _StreakCalendar extends StatelessWidget {
  const _StreakCalendar({required this.practiceDates, required this.streak});
  final List<DateTime> practiceDates;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const days = 35;
    final today = DateTime.now();
    final practiced = practiceDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$streak-day streak', style: AppTypography.labelLarge(c.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < days; i++)
              Builder(builder: (_) {
                final day = DateTime(today.year, today.month, today.day)
                    .subtract(Duration(days: days - 1 - i));
                // If we have explicit practice dates use them; otherwise fall back
                // to lighting the most recent `streak` cells.
                final lit = practiced.isNotEmpty
                    ? practiced.contains(day)
                    : i >= days - streak;
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lit ? c.accent : c.bgRaised,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: c.borderSubtle),
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }
}
