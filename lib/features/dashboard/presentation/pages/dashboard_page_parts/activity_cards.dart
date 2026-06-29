part of '../dashboard_page.dart';

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
                  borderRadius: AppRadii.cardR,
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
      borderRadius: AppRadii.cardR,
      child: _ShellCard(
        icon: LucideIcons.play,
        title: 'Continue Learning',
        subtitle: lastStudied != null ? 'Pick up where you left off' : 'Start a new session',
        child: lastStudied != null
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: AppRadii.cardR,
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
                  borderRadius: AppRadii.cardR,
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
                  borderRadius: AppRadii.componentR,
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
                  decoration: BoxDecoration(color: c.accentLight, borderRadius: AppRadii.pillR),
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
            borderRadius: AppRadii.pillR,
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
