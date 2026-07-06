part of '../dashboard_page.dart';

class _MasteryOverview extends StatelessWidget {
  const _MasteryOverview({required this.data});
  final DashboardData data;

  static const _states = MasteryVisuals.states;

  static String _stateOf(double mastery) {
    if (mastery < 0.4) return 'WEAK';
    if (mastery < 0.6) return 'LEARNING';
    if (mastery < 0.8) return 'PRACTICING';
    return 'MASTERED';
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
                      borderRadius: AppRadii.sectionR,
                    ),
                    child: Column(
                      children: [
                        Text(MasteryVisuals.emojiFor(_states[i]),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('${counts[_states[i]]}',
                            style: AppTypography.statNumber(c.textPrimary, size: 18)),
                        const SizedBox(height: 2),
                        Text(MasteryVisuals.labelFor(_states[i]).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: AppTypography.mono(
                                MasteryVisuals.colorFor(_states[i], c), size: 9)),
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
              borderRadius: AppRadii.pillR,
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final s in _states)
                      if ((counts[s] ?? 0) > 0)
                        Expanded(
                          flex: counts[s]!,
                          child: Container(color: MasteryVisuals.colorFor(s, c)),
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
              stateColor: (ctx, s) => MasteryVisuals.colorFor(s, ctx.colors),
            );
            final strongest0 = _TopicList(
              icon: LucideIcons.arrowUpRight,
              color: c.success,
              title: 'STRONGEST',
              subjects: strongest,
              stateColor: (ctx, s) => MasteryVisuals.colorFor(s, ctx.colors),
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
        borderRadius: AppRadii.sectionR,
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
                      borderRadius: AppRadii.cardR,
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
