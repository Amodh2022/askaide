part of '../role_dashboard_pages.dart';

class _TeacherSubjectView extends StatelessWidget {
  const _TeacherSubjectView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherSubjectCubit, TeacherSubjectState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const _TeacherSubjectSkeleton();
        final d = state.dashboard;
        final inactiveCount = d.totalStudents - d.activeThisWeek;
        final atRisk = d.studentsNeedingHelp;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Teacher Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('SUBJECT DASHBOARD', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 4),
                  Text(d.subjectName.isEmpty ? 'Subject' : d.subjectName,
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionButton(
                        label: 'Students',
                        icon: LucideIcons.users,
                        onTap: () => context.go('/teacher/subject/$subjectId/students'),
                        filled: true,
                      ),
                      _ActionButton(
                        label: 'Weak Topics',
                        icon: LucideIcons.triangleAlert,
                        onTap: () => context.go('/teacher/subject/$subjectId/weak-topics'),
                        danger: true,
                      ),
                      _ActionButton(
                        label: 'Activity',
                        icon: LucideIcons.activity,
                        onTap: () => context.go('/teacher/subject/$subjectId/activity'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // KPI cards
                  Row(
                    children: [
                      _KpiCard(
                        icon: LucideIcons.users,
                        label: 'Total Students',
                        value: '${d.totalStudents}',
                        sub: '${d.activeThisWeek} active this week',
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        icon: LucideIcons.trendingUp,
                        label: 'Avg Mastery',
                        value: '${(d.avgMastery * 100).round()}%',
                        sub: '${(d.avgCoverage * 100).round()}% coverage',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _KpiCard(
                        icon: LucideIcons.barChart3,
                        label: 'Coverage',
                        value: '${(d.avgCoverage * 100).round()}%',
                        sub: 'Syllabus covered',
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        icon: LucideIcons.triangleAlert,
                        label: 'Need Help',
                        value: '${d.studentsNeedingHelp}',
                        sub: 'Students struggling',
                        danger: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // At-risk alert
                  if (inactiveCount > 0 || atRisk > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.danger.withValues(alpha: 0.08),
                        border: Border.all(color: c.danger.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.triangleAlert, size: 15, color: c.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 20,
                              children: [
                                if (inactiveCount > 0)
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: '$inactiveCount',
                                        style: AppTypography.mono(c.danger, size: 12).copyWith(fontWeight: FontWeight.w700)),
                                    TextSpan(
                                        text: ' student${inactiveCount > 1 ? 's' : ''} inactive this week',
                                        style: AppTypography.bodySmall(c.textPrimary)),
                                  ])),
                                if (atRisk > 0)
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: '$atRisk',
                                        style: AppTypography.mono(c.danger, size: 12).copyWith(fontWeight: FontWeight.w700)),
                                    TextSpan(
                                        text: ' student${atRisk > 1 ? 's' : ''} need extra help',
                                        style: AppTypography.bodySmall(c.textPrimary)),
                                  ])),
                              ],
                            ),
                          ),
                          if (atRisk > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.go('/teacher/subject/$subjectId/students'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(4)),
                                child: Text('View', style: AppTypography.mono(Colors.white, size: 10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Chapter Progress
                  Row(
                    children: [
                      Icon(LucideIcons.bookOpen, size: 15, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Chapter Progress',
                          style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                      const Spacer(),
                      Text('${d.chapterProgress.length} chapters',
                          style: AppTypography.mono(c.textMuted, size: 10)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (d.chapterProgress.isEmpty)
                    Text('No chapter data.', style: AppTypography.bodyMedium(c.textMuted))
                  else
                    for (final ch in d.chapterProgress)
                      _ChapterProgressCard(chapter: ch, subjectId: subjectId),

                  const SizedBox(height: 24),

                  // Top Weak Topics
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Top Weak Topics',
                                style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.go('/teacher/subject/$subjectId/weak-topics'),
                              child: Text('View All',
                                  style: AppTypography.bodySmall(c.accent).copyWith(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (d.topWeakTopics.isEmpty)
                          Text('No weak topics — great work!', style: AppTypography.bodySmall(c.textMuted))
                        else
                          for (final t in d.topWeakTopics.take(3))
                            _WeakTopicChip(topic: t),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Class Summary
                  if (d.classSummary.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: context.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.listChecks, size: 15, color: c.accent),
                              const SizedBox(width: 8),
                              Text('Class Summary',
                                  style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < d.classSummary.length; i++) ...[
                            _ClassSummaryRow(item: d.classSummary[i]),
                            if (i < d.classSummary.length - 1)
                              Divider(color: c.border, height: 1),
                          ],
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

class _ChapterProgressCard extends StatelessWidget {
  const _ChapterProgressCard({required this.chapter, required this.subjectId});
  final ChapterProgress chapter;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final masteryPct = (chapter.classAvgMastery * 100).round();

    return GestureDetector(
      onTap: () => context.go('/teacher/subject/$subjectId/chapter/${chapter.chapterId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: context.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c.bgCard,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                chapter.order.toString().padLeft(2, '0'),
                style: AppTypography.mono(c.textMuted, size: 12).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(chapter.name,
                            style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w500),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      if (chapter.status.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StatusBadge(chapter.status),
                      ],
                      const SizedBox(width: 8),
                      // Avg mastery, folded into the title row so the chapter
                      // name keeps full width on narrow (mobile) layouts.
                      Text('$masteryPct%',
                          style: AppTypography.mono(c.accent, size: 15)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Single mastery bar (mirrors the frontend's ProgressBar).
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      height: 4,
                      color: c.border,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: chapter.classAvgMastery.clamp(0.0, 1.0),
                          child: ColoredBox(color: _masteryBarColor(chapter.classAvgMastery, c)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Text('${chapter.studentsCompleted} done', style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Text('${chapter.studentsInProgress} in progress', style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: c.border, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Text('${chapter.studentsNotStarted} not started', style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _WeakTopicChip extends StatelessWidget {
  const _WeakTopicChip({required this.topic});
  final TopWeakTopicItem topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.name,
                    style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(topic.chapterName, style: AppTypography.bodySmall(c.textMuted), maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.triangleAlert, size: 13, color: c.danger),
          const SizedBox(width: 4),
          Text('${topic.studentsWeak}',
              style: AppTypography.mono(c.danger, size: 11).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('weak', style: AppTypography.bodySmall(c.textMuted)),
        ],
      ),
    );
  }
}

class _ClassSummaryRow extends StatelessWidget {
  const _ClassSummaryRow({required this.item});
  final ClassSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: c.accentLight, borderRadius: BorderRadius.circular(4)),
            child: Icon(LucideIcons.users, size: 14, color: c.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.className} — ${item.sectionName}',
                    style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                Text('${item.studentCount} students', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(item.avgMastery * 100).round()}%',
                  style: AppTypography.mono(c.accent, size: 13).copyWith(fontWeight: FontWeight.w700)),
              Text('mastery', style: AppTypography.bodySmall(c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
