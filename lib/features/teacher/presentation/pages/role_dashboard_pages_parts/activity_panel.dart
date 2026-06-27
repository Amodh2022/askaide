part of '../role_dashboard_pages.dart';

class _TeacherActivityView extends StatelessWidget {
  const _TeacherActivityView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherActivityCubit, TeacherActivityState>(
      builder: (context, state) {
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
                  Row(
                    children: [
                      Icon(LucideIcons.activity, size: 22, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Activity Feed',
                          style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w700, fontSize: 24)),
                    ],
                  ),
                  Text('Recent student activity', style: AppTypography.bodySmall(c.textMuted)),
                  const SizedBox(height: 20),

                  if (state.status == TLoad.loading)
                    const SkeletonListLoader()
                  else if (state.activities.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.activity, size: 32, color: c.textMuted),
                          const SizedBox(height: 8),
                          Text('No recent activity', style: AppTypography.bodyMedium(c.textMuted)),
                        ],
                      ),
                    )
                  else
                    for (final a in state.activities) _ActivityCard(activity: a),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = activity.type.toUpperCase();

    final (typeIcon, typeColor) = switch (type) {
      'SESSION_COMPLETED' => (LucideIcons.checkCircle, c.accent),
      'MASTERY_ACHIEVED' => (LucideIcons.trophy, c.warning),
      'CHAPTER_STARTED' => (LucideIcons.playCircle, c.textMuted),
      _ => (LucideIcons.activity, c.textMuted),
    };

    final actionLabel = switch (type) {
      'SESSION_COMPLETED' => 'completed a session',
      'MASTERY_ACHIEVED' => 'mastered a topic',
      'CHAPTER_STARTED' => 'started a chapter',
      _ => activity.type,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              activity.studentName.isNotEmpty ? activity.studentName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: activity.studentName,
                      style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  TextSpan(text: ' $actionLabel', style: AppTypography.bodyMedium(c.textSecondary)),
                ])),
                const SizedBox(height: 4),
                if (type == 'SESSION_COMPLETED' && activity.chapter.isNotEmpty)
                  Text('📖 ${activity.chapter}  •  ${activity.correctAnswers}/${activity.questionsAttempted} correct (${(activity.score * 100).round()}%)',
                      style: AppTypography.bodySmall(c.textMuted)),
                if (type == 'MASTERY_ACHIEVED')
                  Text('🎯 ${activity.topic.isNotEmpty ? '${activity.topic} in ' : ''}${activity.chapter}',
                      style: AppTypography.bodySmall(c.textMuted)),
                if (type == 'CHAPTER_STARTED' && activity.chapter.isNotEmpty)
                  Text('📚 Started ${activity.chapter}', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(typeIcon, size: 14, color: typeColor),
              ),
              const SizedBox(height: 4),
              Text(_relativeTime(activity.timestamp), style: AppTypography.mono(c.textMuted, size: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
