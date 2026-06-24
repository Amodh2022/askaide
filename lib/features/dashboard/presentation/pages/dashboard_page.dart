import 'dart:math' as math;

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
      child: SingleChildScrollView(
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 96),
                    child: Center(child: CircularProgressIndicator()),
                  )
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
    );
  }
}

/// A rounded icon tile with a 135° accent gradient and a white glyph — the
/// header icon used across the React dashboard cards.
class _GradientIcon extends StatelessWidget {
  const _GradientIcon(this.icon, {this.secondary = false});
  final IconData icon;
  final bool secondary;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = secondary ? c.accentSecondary : c.accent;
    final dark = Color.lerp(base, Colors.black, 0.3)!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, dark],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

/// A responsive grid of equal-width cards (auto-fit, min [minWidth] wide).
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

/// The full streak display from the frontend: current streak (gradient flame
/// number + milestone bar), best streak, freeze count, and next milestone —
/// each a labelled segment separated by thin dividers.
class _StreakDisplay extends StatelessWidget {
  const _StreakDisplay({
    required this.data,
    required this.practicedToday,
    required this.loading,
  });
  final DashboardData data;
  final bool practicedToday;
  final bool loading;

  static const _flame = Color(0xFFE8722A);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (loading) {
      return Container(
        width: 90,
        height: 36,
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.border),
        ),
      );
    }

    final current = data.currentStreak;
    final best = data.longestStreak;
    final freezes = data.freezesRemaining;
    final nextMilestone = (current / 5).ceil() * 5 + (current % 5 == 0 ? 5 : 0);
    final prevMilestone = nextMilestone - 5;
    final milestoneProgress =
        current > 0 ? ((current - prevMilestone) / 5).clamp(0.0, 1.0) : 0.0;
    final atRisk = !practicedToday && current > 0;

    final divider = Container(width: 1, height: 28, color: c.border);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: atRisk ? _flame.withValues(alpha: 0.5) : c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current streak
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.flame,
                      size: 14, color: current > 0 ? _flame : c.textMuted),
                  const SizedBox(width: 4),
                  if (current > 0)
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_flame, Color(0xFFFFB347)],
                      ).createShader(b),
                      child: Text('$current',
                          style: AppTypography.mono(Colors.white, size: 22)
                              .copyWith(fontWeight: FontWeight.w800, height: 1)),
                    )
                  else
                    Text('0',
                        style: AppTypography.mono(c.textMuted, size: 22)
                            .copyWith(fontWeight: FontWeight.w800, height: 1)),
                ],
              ),
              const SizedBox(height: 3),
              Text(practicedToday ? 'TODAY ✓' : 'STREAK',
                  style: AppTypography.mono(practicedToday ? c.accent : c.textMuted, size: 9)
                      .copyWith(letterSpacing: 1)),
              if (current > 0) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: 36,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: milestoneProgress,
                      minHeight: 3,
                      backgroundColor: c.border,
                      valueColor: AlwaysStoppedAnimation(c.accent),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 14),
          divider,
          const SizedBox(width: 14),
          // Best streak
          _MetricSegment(
            icon: LucideIcons.trophy,
            iconColor: c.accentSecondary,
            value: '$best',
            label: best > 0 && current >= best ? 'PERSONAL BEST!' : 'BEST',
            labelColor: best > 0 && current >= best ? c.accent : c.textMuted,
          ),
          const SizedBox(width: 14),
          divider,
          const SizedBox(width: 14),
          // Freeze
          _MetricSegment(
            icon: freezes > 0 ? LucideIcons.shield : LucideIcons.shieldOff,
            iconColor: freezes > 0 ? c.accent : c.textMuted,
            value: '$freezes',
            label: 'FREEZE',
            labelColor: c.textMuted,
          ),
          const SizedBox(width: 14),
          divider,
          const SizedBox(width: 14),
          // Next milestone
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$nextMilestone',
                  style: AppTypography.mono(c.textPrimary, size: 16)
                      .copyWith(fontWeight: FontWeight.w700, height: 1)),
              const SizedBox(height: 3),
              Text('GOAL',
                  style: AppTypography.mono(c.textMuted, size: 9).copyWith(letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small icon + number + mono label column used inside [_StreakDisplay].
class _MetricSegment extends StatelessWidget {
  const _MetricSegment({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.labelColor,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color labelColor;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(value,
                style: AppTypography.mono(c.textPrimary, size: 16)
                    .copyWith(fontWeight: FontWeight.w700, height: 1)),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: AppTypography.mono(labelColor, size: 9).copyWith(letterSpacing: 1)),
      ],
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

/// Accent banner inviting the user to resume their unfinished session, with a
/// dismiss affordance (mirrors the frontend ContinueSessionBanner).
class _ContinueBanner extends StatefulWidget {
  const _ContinueBanner({required this.session});
  final ContinueSessionInfo session;
  @override
  State<_ContinueBanner> createState() => _ContinueBannerState();
}

class _ContinueBannerState extends State<_ContinueBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final c = context.colors;
    final session = widget.session;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(6)),
      child: Stack(
        children: [
          Row(
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
                      style: AppTypography.mono(Colors.white70, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.go(RoutePaths.study),
                icon: const Icon(LucideIcons.play, size: 13),
                label: const Text('Resume'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: () => setState(() => _dismissed = true),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime? d) {
    if (d == null) return 'recently';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
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
                    _GradientIcon(
                      done ? LucideIcons.circleCheckBig : LucideIcons.zap,
                      secondary: !done,
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
                ] else ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              'I just scored ${challenge.score}/${challenge.totalQuestions} '
                              "on today's Daily Challenge in ${challenge.subjectName}! 🎯 "
                              'Try AskAide and beat my score!',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Result copied!')),
                        );
                      },
                      icon: const Icon(LucideIcons.share2, size: 15),
                      label: const Text('Share result'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.accent,
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (challenge.completedAt != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clock, size: 12, color: c.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Completed at ${TimeOfDay.fromDateTime(challenge.completedAt!.toLocal()).format(context)}',
                            style: AppTypography.bodySmall(c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
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

/// Weekly-activity bar chart with a gradient-icon header, total questions,
/// per-bar counts, and an avg-accuracy / active-days footer.
class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({required this.weekly});
  final List<DayActivity> weekly;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxQ = weekly.fold<int>(1, (m, d) => d.questions > m ? d.questions : m);
    final total = weekly.fold<int>(0, (s, d) => s + d.questions);
    final active = weekly.where((d) => d.questions > 0).toList();
    final avgAccuracy = active.isEmpty
        ? 0
        : (active.fold<double>(0, (s, d) => s + d.accuracy) / active.length).round();
    final barColorActive = Color.lerp(c.bgSecondary, c.accent, 0.6)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const _GradientIcon(LucideIcons.chartColumn),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Activity',
                        style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                    Text('Last 7 days', style: AppTypography.bodySmall(c.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$total', style: AppTypography.statNumber(c.textPrimary, size: 18)),
                  Text('QUESTIONS', style: AppTypography.mono(c.textMuted, size: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bars
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in weekly)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.questions > 0)
                          Text('${d.questions}',
                              style: AppTypography.mono(d.isToday ? c.accent : c.textMuted, size: 9)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Container(
                          height: (d.questions / maxQ * 80).clamp(4, 80).toDouble(),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: d.isToday
                                ? c.accent
                                : d.questions > 0
                                    ? barColorActive
                                    : c.bgSecondary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            children: [
              for (final d in weekly)
                Expanded(
                  child: Text(d.isToday ? 'Today' : d.label,
                      textAlign: TextAlign.center,
                      style: AppTypography.mono(d.isToday ? c.accent : c.textMuted, size: 10)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          // Summary footer
          if (avgAccuracy > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(TextSpan(
                    style: AppTypography.bodySmall(c.textSecondary),
                    children: [
                      const TextSpan(text: 'Avg accuracy: '),
                      TextSpan(
                          text: '$avgAccuracy%',
                          style: AppTypography.bodySmall(c.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  )),
                  const SizedBox(width: 16),
                  Container(width: 4, height: 4, decoration: BoxDecoration(color: c.border, shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Text.rich(TextSpan(
                    style: AppTypography.bodySmall(c.textSecondary),
                    children: [
                      const TextSpan(text: 'Active days: '),
                      TextSpan(
                          text: '${active.length}/7',
                          style: AppTypography.bodySmall(c.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// GitHub-style 90-day practice heatmap (week columns), mirroring the frontend
/// StreakCalendar.
class _PracticeCalendarCard extends StatelessWidget {
  const _PracticeCalendarCard({required this.practiceDates});
  final List<DateTime> practiceDates;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final practiced =
        practiceDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    // Build the last 90 days, oldest first.
    final days = <_CalDay>[];
    for (var i = 89; i >= 0; i--) {
      final d = todayD.subtract(Duration(days: i));
      days.add(_CalDay(d, practiced.contains(d), i == 0));
    }
    // Pad the first column so the grid starts on a Sunday (weekday%7: Sun=0).
    final firstPad = days.first.date.weekday % 7;
    final cells = <_CalDay?>[...List<_CalDay?>.filled(firstPad, null), ...days];
    final weeks = <List<_CalDay?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, math.min(i + 7, cells.length)));
    }

    Color cellColor(_CalDay? d) {
      if (d == null) return Colors.transparent;
      if (d.isToday && !d.practiced) return c.border;
      if (d.practiced) return c.accent;
      return c.bgSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Practice Calendar',
                  style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${practiceDates.length} days practiced',
                    style: AppTypography.bodySmall(c.accent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final week in weeks)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Column(
                      children: [
                        for (final day in week)
                          Container(
                            width: 13,
                            height: 13,
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: cellColor(day),
                              borderRadius: BorderRadius.circular(3),
                              border: day != null && day.isToday
                                  ? Border.all(color: c.accent, width: 1)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: AppTypography.mono(c.textMuted, size: 10)),
              const SizedBox(width: 6),
              _LegendCell(c.bgSecondary),
              _LegendCell(c.accent.withValues(alpha: 0.4)),
              _LegendCell(c.accent.withValues(alpha: 0.7)),
              _LegendCell(c.accent),
              const SizedBox(width: 6),
              Text('More', style: AppTypography.mono(c.textMuted, size: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendCell extends StatelessWidget {
  const _LegendCell(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}

class _CalDay {
  const _CalDay(this.date, this.practiced, this.isToday);
  final DateTime date;
  final bool practiced;
  final bool isToday;
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

/// Referral invite card — gradient accent, code in a dashed box, and a link to
/// the referral page (mirrors the frontend ReferralCard).
class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral});
  final ReferralSummary? referral;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasCode = referral != null && referral!.code.isNotEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.accent, c.accentSecondary]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _GradientIcon(LucideIcons.gift, secondary: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Refer a Friend',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                          Text('Both get a streak freeze!',
                              style: AppTypography.bodySmall(c.textSecondary)),
                        ],
                      ),
                    ),
                    if (referral != null && referral!.totalReferrals > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.accentLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.users, size: 13, color: c.accent),
                          const SizedBox(width: 4),
                          Text('${referral!.totalReferrals}',
                              style: AppTypography.mono(c.accent, size: 11)),
                        ]),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (hasCode) ...[
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
                        Text('Your referral code',
                            style: AppTypography.bodySmall(c.textMuted)),
                        const SizedBox(height: 6),
                        DottedBorderBox(
                          color: c.border,
                          child: Center(
                            child: Text(referral!.code,
                                style: AppTypography.mono(c.textPrimary, size: 18)
                                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Invite friends — you both get a streak freeze.',
                        style: AppTypography.bodySmall(c.textMuted)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (hasCode) {
                        Clipboard.setData(ClipboardData(
                          text:
                              '🎯 Join me on AskAide — AI-powered practice for CBSE students! '
                              'Use my referral code: ${referral!.code} and we both get a streak freeze!',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Referral message copied!')),
                        );
                      } else {
                        context.go(RoutePaths.referral);
                      }
                    },
                    icon: const Icon(LucideIcons.share2, size: 15),
                    label: Text(hasCode ? 'Share & Earn' : 'Refer & Earn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A box with a dashed border (for the referral code).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.color});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, radius: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, this.radius = 8});
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
            metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}

/// The full achievements grid from the frontend: progress bar, earned/total
/// count, and a 6-up grid of badge tiles (locked tiles are dimmed + locked).
class _AchievementsCard extends StatefulWidget {
  const _AchievementsCard({required this.earned});
  final List<String> earned;
  @override
  State<_AchievementsCard> createState() => _AchievementsCardState();
}

class _AchievementsCardState extends State<_AchievementsCard> {
  bool _showAll = false;

  static const _maxVisible = 6;

  // The badge catalog, synced with the frontend `constants/badges.js`.
  static const _catalog = <({String id, String name, String emoji})>[
    (id: 'first_session', name: 'First Steps', emoji: '🎯'),
    (id: 'quick_learner', name: 'Quick Learner', emoji: '📚'),
    (id: 'study_1_hour', name: 'Warm Up', emoji: '⏱️'),
    (id: 'study_10_hours', name: 'Getting Serious', emoji: '📖'),
    (id: 'study_20_hours', name: 'Bookworm', emoji: '🐛'),
    (id: 'dedicated_student', name: 'Dedicated Student', emoji: '🎓'),
    (id: 'perfect_score', name: 'Perfect Score', emoji: '⭐'),
    (id: 'math_master', name: 'Math Master', emoji: '🧮'),
    (id: 'night_owl', name: 'Night Owl', emoji: '🦉'),
    (id: 'early_bird', name: 'Early Bird', emoji: '🌅'),
    (id: 'streak_keeper', name: 'Streak Starter', emoji: '🔥'),
    (id: 'streak_14_days', name: 'Week Warrior', emoji: '⚡'),
    (id: 'streak_30_days', name: 'Streak Master', emoji: '🏆'),
    (id: 'weekend_warrior', name: 'Weekend Warrior', emoji: '🎮'),
    (id: 'comeback', name: 'Comeback King', emoji: '👑'),
    (id: 'subject_specialist', name: 'Subject Explorer', emoji: '🌍'),
  ];

  bool _isEarned(({String id, String name, String emoji}) badge) {
    final hay = widget.earned.map((e) => e.toLowerCase());
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return hay.any((e) => e.contains(id) || e.contains(name));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final earnedFlags = {for (final b in _catalog) b.id: _isEarned(b)};
    final earnedCount = earnedFlags.values.where((v) => v).length;
    final total = _catalog.length;

    // Earned first, then locked.
    final sorted = [..._catalog]..sort((a, b) {
        final ea = earnedFlags[a.id]!, eb = earnedFlags[b.id]!;
        if (ea && !eb) return -1;
        if (!ea && eb) return 1;
        return 0;
      });
    final visible = _showAll ? sorted : sorted.take(_maxVisible).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _GradientIcon(LucideIcons.trophy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Achievements',
                        style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                    Text('$earnedCount/$total badges earned',
                        style: AppTypography.bodySmall(c.textSecondary)),
                  ],
                ),
              ),
              if (sorted.length > _maxVisible)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  style: TextButton.styleFrom(
                    foregroundColor: c.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: c.accentLight,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(_showAll ? 'Show Less' : 'View All',
                      style: AppTypography.bodySmall(c.accent)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total > 0 ? earnedCount / total : 0,
              minHeight: 6,
              backgroundColor: c.bgSecondary,
              valueColor: AlwaysStoppedAnimation(c.accent),
            ),
          ),
          const SizedBox(height: 14),
          if (earnedCount == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text("No badges yet — you're just getting started",
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge(c.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Complete sessions, build your streak, and unlock achievements.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(c.textMuted)),
                ],
              ),
            )
          else
            LayoutBuilder(builder: (context, cons) {
              final cols = cons.maxWidth > 360 ? 6 : 3;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: [
                  for (final b in visible)
                    _BadgeTile(
                      name: b.name,
                      emoji: b.emoji,
                      earned: earnedFlags[b.id]!,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.name, required this.emoji, required this.earned});
  final String name;
  final String emoji;
  final bool earned;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.border),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: earned ? 1 : 0.35,
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 4),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(earned ? c.textPrimary : c.textMuted)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          if (!earned)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(LucideIcons.lock, size: 12, color: c.textMuted),
            ),
        ],
      ),
    );
  }
}

/// Class leaderboard card with rank medals, avatars, question counts and
/// accuracy — mirrors the frontend ClassLeaderboard.
class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final myIndex = entries.indexWhere((e) => e.isCurrentUser);
    final myRank = myIndex >= 0 ? myIndex + 1 : null;
    final topPct = (myRank != null && entries.isNotEmpty)
        ? math.max(1, (myRank / entries.length * 100).round())
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _GradientIcon(LucideIcons.trophy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leaderboard',
                        style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                    Text('Top learners this week',
                        style: AppTypography.bodySmall(c.textSecondary)),
                  ],
                ),
              ),
              if (myRank != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Your rank: #$myRank',
                      style: AppTypography.bodySmall(c.accent)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.trophy, size: 24, color: c.accent),
                ),
                const SizedBox(height: 12),
                Text('No rankings yet',
                    style: AppTypography.labelLarge(c.textPrimary)),
                const SizedBox(height: 4),
                Text('Start studying to appear on the leaderboard!',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(c.textSecondary)),
              ],
            )
          else ...[
            if (topPct != null) ...[
              Center(
                child: Text("You're in the top $topPct% of today's learners",
                    style: AppTypography.bodySmall(c.textMuted)),
              ),
              const SizedBox(height: 10),
            ],
            for (var i = 0; i < entries.length && i < 10; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeaderboardRow(entry: entries[i], rank: i + 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.rank});
  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isMe = entry.isCurrentUser;
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = Icon(LucideIcons.trophy, size: 16, color: c.warning);
    } else if (rank == 2) {
      rankWidget = Icon(LucideIcons.medal, size: 16, color: c.textMuted);
    } else if (rank == 3) {
      rankWidget = Icon(LucideIcons.medal, size: 16, color: c.warning);
    } else {
      rankWidget = Text('$rank',
          textAlign: TextAlign.center,
          style: AppTypography.mono(c.textMuted, size: 12).copyWith(fontWeight: FontWeight.w700));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? c.accentLight : c.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? c.accent.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: Row(
        children: [
          SizedBox(width: 20, child: Center(child: rankWidget)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: isMe ? c.accent : c.accentSecondary,
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : 'U',
              style: AppTypography.mono(Colors.white, size: 12).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? '${entry.name} (You)' : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium(isMe ? c.accent : c.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.totalQuestions}',
                  style: AppTypography.bodyMedium(c.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700)),
              Text('Qs', style: AppTypography.mono(c.textMuted, size: 10)),
            ],
          ),
          if (entry.accuracy != null) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${entry.accuracy!.round()}%',
                      style: AppTypography.bodyMedium(c.accentSecondary)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text('Acc', style: AppTypography.mono(c.textMuted, size: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mastery progress overview — state-count tiles, a stacked distribution bar,
/// and the weakest/strongest subjects, mirroring the frontend MasteryOverview.
class _MasteryOverview extends StatelessWidget {
  const _MasteryOverview({required this.data});
  final DashboardData data;

  static const _states = ['WEAK', 'LEARNING', 'PRACTICING', 'MASTERED'];
  static const _emoji = {
    'WEAK': '🔴',
    'LEARNING': '🟡',
    'PRACTICING': '🟢',
    'MASTERED': '🏆',
  };
  static const _label = {
    'WEAK': 'Weak',
    'LEARNING': 'Learning',
    'PRACTICING': 'Practicing',
    'MASTERED': 'Mastered',
  };

  static String _stateOf(double mastery) {
    if (mastery < 0.4) return 'WEAK';
    if (mastery < 0.6) return 'LEARNING';
    if (mastery < 0.8) return 'PRACTICING';
    return 'MASTERED';
  }

  Color _stateColor(BuildContext context, String state) {
    final c = context.colors;
    switch (state) {
      case 'WEAK':
        return c.error;
      case 'LEARNING':
        return c.warning;
      case 'PRACTICING':
        return c.success;
      default:
        return c.accentSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subjects = data.subjects;
    final total = subjects.length;
    final counts = {for (final s in _states) s: 0};
    for (final s in subjects) {
      final st = _stateOf(s.mastery);
      counts[st] = counts[st]! + 1;
    }
    final byMastery = [...subjects]..sort((a, b) => a.mastery.compareTo(b.mastery));
    final weakest = byMastery.take(3).toList();
    final strongest = byMastery.reversed.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _GradientIcon(LucideIcons.trendingUp),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mastery Progress',
                        style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                    Text('$total subjects tracked',
                        style: AppTypography.bodySmall(c.textSecondary)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go(RoutePaths.progress),
                icon: Text('View All', style: AppTypography.bodySmall(c.accent)),
                label: Icon(LucideIcons.chevronRight, size: 14, color: c.accent),
                style: TextButton.styleFrom(
                  backgroundColor: c.accentLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // State count tiles
          Row(
            children: [
              for (var i = 0; i < _states.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: c.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(_emoji[_states[i]]!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('${counts[_states[i]]}',
                            style: AppTypography.statNumber(c.textPrimary, size: 18)),
                        const SizedBox(height: 2),
                        Text(_label[_states[i]]!.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: AppTypography.mono(_stateColor(context, _states[i]), size: 9)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Stacked distribution bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final s in _states)
                      if ((counts[s] ?? 0) > 0)
                        Expanded(
                          flex: counts[s]!,
                          child: Container(color: _stateColor(context, s)),
                        ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Weak / strong lists
          LayoutBuilder(builder: (context, cons) {
            final twoCol = cons.maxWidth > 420;
            final needsWork = _TopicList(
              icon: LucideIcons.arrowDownRight,
              color: c.error,
              title: 'NEEDS WORK',
              subjects: weakest,
              stateColor: _stateColor,
            );
            final strongest0 = _TopicList(
              icon: LucideIcons.arrowUpRight,
              color: c.success,
              title: 'STRONGEST',
              subjects: strongest,
              stateColor: _stateColor,
            );
            if (twoCol) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: needsWork),
                  const SizedBox(width: 12),
                  Expanded(child: strongest0),
                ],
              );
            }
            return Column(
              children: [needsWork, const SizedBox(height: 12), strongest0],
            );
          }),
        ],
      ),
    );
  }
}

class _TopicList extends StatelessWidget {
  const _TopicList({
    required this.icon,
    required this.color,
    required this.title,
    required this.subjects,
    required this.stateColor,
  });
  final IconData icon;
  final Color color;
  final String title;
  final List<SubjectProgress> subjects;
  final Color Function(BuildContext, String) stateColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.mono(color, size: 10).copyWith(letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in subjects)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(c.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${(s.mastery * 100).round()}%',
                        style: AppTypography.mono(
                            stateColor(context, _MasteryOverview._stateOf(s.mastery)),
                            size: 10)),
                  ),
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
