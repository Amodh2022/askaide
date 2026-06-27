part of '../role_dashboard_pages.dart';

class _TeacherWeakTopicsView extends StatelessWidget {
  const _TeacherWeakTopicsView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherWeakTopicsCubit, TeacherWeakTopicsState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const SkeletonListLoader();
        final d = state.data;
        final highCount = d.topics.where((t) => t.teacherAction == 'HIGH_PRIORITY').length;
        final medCount = d.topics.where((t) => t.teacherAction == 'MEDIUM_PRIORITY').length;

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
                  Text('WEAK TOPICS REPORT', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 4),
                  Text('Areas Needing Attention',
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  Text('${d.totalWeakTopics} topic${d.totalWeakTopics != 1 ? 's' : ''} flagged for review',
                      style: AppTypography.bodySmall(c.textMuted)),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    children: [
                      if (highCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.danger.withValues(alpha: 0.1),
                            border: Border.all(color: c.danger),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$highCount',
                                  style: AppTypography.mono(c.danger, size: 11).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('High Priority', style: AppTypography.bodySmall(c.danger)),
                            ],
                          ),
                        ),
                      if (medCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.warning.withValues(alpha: 0.1),
                            border: Border.all(color: c.warning),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$medCount',
                                  style: AppTypography.mono(c.warning, size: 11).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('Medium Priority', style: AppTypography.bodySmall(c.warning)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (d.classroomRecommendation.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.accentLight,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.lightbulb, size: 18, color: c.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Classroom Recommendation',
                                    style: AppTypography.labelLarge(c.textPrimary)),
                                const SizedBox(height: 4),
                                Text(d.classroomRecommendation,
                                    style: AppTypography.bodyMedium(c.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (d.topics.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.checkCircle, size: 32, color: c.accent),
                          const SizedBox(height: 8),
                          Text('No weak topics — great work!', style: AppTypography.bodyMedium(c.textMuted)),
                        ],
                      ),
                    )
                  else
                    for (final topic in d.topics) _WeakTopicDetailCard(topic: topic),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeakTopicDetailCard extends StatelessWidget {
  const _WeakTopicDetailCard({required this.topic});
  final WeakTopicDetail topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final borderColor = topic.teacherAction == 'HIGH_PRIORITY'
        ? c.danger
        : topic.teacherAction == 'MEDIUM_PRIORITY' ? c.warning : c.accent;
    final bgColor = topic.teacherAction == 'HIGH_PRIORITY'
        ? c.danger.withValues(alpha: 0.07)
        : topic.teacherAction == 'MEDIUM_PRIORITY' ? c.warning.withValues(alpha: 0.07) : c.accentLight;

    // Rounded card with a full-height 3px left accent bar. A non-uniform
    // Border can't be combined with borderRadius in Flutter, so the accent is
    // a separate strip (mirrors the frontend's `border-l-4`).
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: borderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(topic.name,
                              style: AppTypography.labelLarge(c.textPrimary).copyWith(fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(topic.teacherAction),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(topic.chapterName, style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${topic.weakPercentage}%',
                      style: AppTypography.mono(borderColor, size: 22).copyWith(fontWeight: FontWeight.w700, height: 1)),
                  Text('students weak', style: AppTypography.bodySmall(c.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(LucideIcons.trendingDown, size: 13, color: borderColor),
              const SizedBox(width: 4),
              Text('${topic.studentsWeak} of ${topic.totalStudents} weak',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(width: 16),
              Icon(LucideIcons.target, size: 13, color: c.accent),
              const SizedBox(width: 4),
              Text('${(topic.avgMastery * 100).round()}% avg mastery',
                  style: AppTypography.bodySmall(c.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _DiffBar(label: 'Easy', value: topic.difficulty.easy, color: c.accent)),
              const SizedBox(width: 8),
              Expanded(child: _DiffBar(label: 'Medium', value: topic.difficulty.medium, color: c.warning)),
              const SizedBox(width: 8),
              Expanded(child: _DiffBar(label: 'Hard', value: topic.difficulty.hard, color: c.danger)),
            ],
          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffBar extends StatelessWidget {
  const _DiffBar({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.mono(c.textMuted, size: 9)),
            Text('${(value * 100).round()}%',
                style: AppTypography.mono(color, size: 9).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: c.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
