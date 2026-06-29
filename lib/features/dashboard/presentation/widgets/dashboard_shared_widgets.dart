import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_models.dart';

/// Icon in a rounded gradient tile — the leading icon on several
/// dashboard/profile cards (achievements, leaderboard, referral, mastery).
class GradientIcon extends StatelessWidget {
  const GradientIcon(this.icon, {super.key, this.secondary = false});
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
        borderRadius: AppRadii.sectionR,
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

/// The full streak display from the frontend: current streak (gradient flame
/// number + milestone bar), best streak, freeze count, and next milestone —
/// each a labelled segment separated by thin dividers. Used on both the
/// dashboard hero and the profile page.
class StreakDisplay extends StatelessWidget {
  const StreakDisplay({
    super.key,
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
          borderRadius: AppRadii.cardR,
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
        borderRadius: AppRadii.cardR,
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
                  const SizedBox(width: AppSpacing.xxs),
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
                const SizedBox(height: AppSpacing.xxs),
                SizedBox(
                  width: 36,
                  child: ClipRRect(
                    borderRadius: AppRadii.pillR,
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
          MetricSegment(
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
          MetricSegment(
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

/// A small icon + number + mono label column used inside [StreakDisplay].
class MetricSegment extends StatelessWidget {
  const MetricSegment({
    super.key,
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
            const SizedBox(width: AppSpacing.xxs),
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

/// The full achievements grid from the frontend: progress bar, earned/total
/// count, and a 6-up grid of badge tiles (locked tiles are dimmed + locked).
/// Used on both the dashboard and the profile page.
class AchievementsCard extends StatefulWidget {
  const AchievementsCard({super.key, required this.earned});
  final List<String> earned;
  @override
  State<AchievementsCard> createState() => _AchievementsCardState();
}

class _AchievementsCardState extends State<AchievementsCard> {
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
              const GradientIcon(LucideIcons.trophy),
              const SizedBox(width: AppSpacing.sm),
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
            borderRadius: AppRadii.pillR,
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
                borderRadius: AppRadii.sectionR,
              ),
              child: Column(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: AppSpacing.xs),
                  Text("No badges yet — you're just getting started",
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge(c.textPrimary)),
                  const SizedBox(height: AppSpacing.xxs),
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
                    BadgeTile(
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

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.name, required this.emoji, required this.earned});
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
        borderRadius: AppRadii.cardR,
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
              const SizedBox(height: AppSpacing.xxs),
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

/// A ring progress gauge with a centred percentage label. Mirrors the
/// frontend `CircularProgress` component — used for mastery/avg-score rings
/// on both the progress and profile pages.
class CircularGauge extends StatelessWidget {
  const CircularGauge({super.key, required this.percent, required this.color, this.size = 92});
  final double percent;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              strokeWidth: 9,
              backgroundColor: c.accentLight,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text('${percent.round()}%', style: AppTypography.statNumber(c.textPrimary, size: 18)),
        ],
      ),
    );
  }
}
