part of '../role_dashboard_pages.dart';

class _TeacherChapterView extends StatelessWidget {
  const _TeacherChapterView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherChapterCubit, TeacherChapterState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const SkeletonListLoader();
        final d = state.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/$subjectId'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Subject Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Chapter ${d.chapterOrder}',
                        style: AppTypography.bodySmall(c.textMuted).copyWith(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Text(d.chapterName.isEmpty ? 'Chapter Analytics' : d.chapterName,
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _KpiCard(icon: LucideIcons.target, label: 'Total Topics', value: '${d.totalTopics}'),
                      const SizedBox(width: 8),
                      _KpiCard(icon: LucideIcons.trendingUp, label: 'Avg Mastery', value: '${(d.avgMastery * 100).round()}%'),
                      const SizedBox(width: 8),
                      _KpiCard(icon: LucideIcons.barChart3, label: 'Avg Coverage', value: '${d.avgCoverage.round()}%'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Icon(LucideIcons.barChart3, size: 16, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Topic Breakdown', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final topic in d.topics) _TopicAnalyticsCard(topic: topic),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.triangleAlert, size: 15, color: c.danger),
                            const SizedBox(width: 8),
                            Text('Struggling Students (${d.strugglingStudents.length})',
                                style: AppTypography.labelLarge(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (d.strugglingStudents.isEmpty)
                          Text('No struggling students — great! 🎉', style: AppTypography.bodySmall(c.textMuted))
                        else
                          for (final s in d.strugglingStudents) _StrugglingStudentCard(student: s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopicAnalyticsCard extends StatelessWidget {
  const _TopicAnalyticsCard({required this.topic});
  final ChapterAnalyticsTopic topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dist = topic.distribution;
    final total = dist.total;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(topic.name,
                          style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    if (topic.status.isNotEmpty) _StatusBadge(topic.status),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${topic.studentsAttempted}/${topic.studentsTotal}',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(width: 8),
              Text('${(topic.classAvgMastery * 100).round()}% avg',
                  style: AppTypography.mono(c.accent, size: 11).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (dist.mastered > 0)
                      Flexible(flex: dist.mastered, child: ColoredBox(color: c.accent)),
                    if (dist.practicing > 0)
                      Flexible(flex: dist.practicing, child: const ColoredBox(color: Colors.blue)),
                    if (dist.learning > 0)
                      Flexible(flex: dist.learning, child: const ColoredBox(color: Colors.purple)),
                    if (dist.weak > 0)
                      Flexible(flex: dist.weak, child: ColoredBox(color: c.danger)),
                    Flexible(flex: total, child: const SizedBox()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                _DistLegend(color: c.accent, label: 'Mastered', count: dist.mastered),
                _DistLegend(color: Colors.blue, label: 'Practicing', count: dist.practicing),
                _DistLegend(color: Colors.purple, label: 'Learning', count: dist.learning),
                _DistLegend(color: c.danger, label: 'Weak', count: dist.weak),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DistLegend extends StatelessWidget {
  const _DistLegend({required this.color, required this.label, required this.count});
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label ($count)', style: AppTypography.bodySmall(context.colors.textMuted)),
      ],
    );
  }
}

class _StrugglingStudentCard extends StatelessWidget {
  const _StrugglingStudentCard({required this.student});
  final StrugglingStudent student;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                Text('${student.weakTopics} weak topics', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          Text('${(student.masteryScore * 100).round()}%',
              style: AppTypography.mono(c.danger, size: 13).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
