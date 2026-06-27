part of '../dashboard_page.dart';

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
