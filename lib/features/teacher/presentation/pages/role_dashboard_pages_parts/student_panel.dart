part of '../role_dashboard_pages.dart';

class _TeacherStudentView extends StatefulWidget {
  const _TeacherStudentView({required this.subjectId});
  final String subjectId;

  @override
  State<_TeacherStudentView> createState() => _TeacherStudentViewState();
}

class _TeacherStudentViewState extends State<_TeacherStudentView> {
  final Set<String> _openChapters = {};

  void _toggle(String id) => setState(() {
        _openChapters.contains(id) ? _openChapters.remove(id) : _openChapters.add(id);
      });

  String _timeAgo(String iso) {
    if (iso.isEmpty) return 'Never';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return d.toLocal().toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherStudentCubit, TeacherStudentState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const SkeletonListLoader();
        final d = state.data;
        final summary = d.subjectSummary;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/${widget.subjectId}/students'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Students', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          d.studentName.isNotEmpty ? d.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.studentName.isEmpty ? 'Student' : d.studentName,
                                style: AppTypography.h3(c.textPrimary).copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '${d.studentClass}${d.studentEmail.isNotEmpty ? '  •  ${d.studentEmail}' : ''}',
                              style: AppTypography.bodySmall(c.textMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subject summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${summary.subjectName} Progress',
                            style: AppTypography.labelLarge(c.textPrimary).copyWith(fontSize: 17)),
                        const SizedBox(height: 16),
                        // 2×2 stat grid (mirrors React's grid-cols-2): two
                        // circular gauges on top, counts below.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MasteryGauge(
                                  value: summary.overallMastery,
                                  size: _GaugeSize.lg,
                                  label: 'Mastery'),
                            ),
                            Expanded(
                              child: _MasteryGauge(
                                  value: summary.overallCoverage,
                                  size: _GaugeSize.lg,
                                  label: 'Coverage'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text('${summary.chaptersStarted}/${summary.totalChapters}',
                                      style: AppTypography.statNumber(c.textPrimary, size: 28)),
                                  Text('Chapters Started', style: AppTypography.mono(c.textMuted, size: 10)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(_timeAgo(summary.lastActive),
                                      style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center),
                                  Text('Last Active', style: AppTypography.mono(c.textMuted, size: 10)),
                                  Text('${summary.totalTimeSpent} min total',
                                      style: AppTypography.bodySmall(c.textMuted), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(LucideIcons.bookOpen, size: 16, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Chapter Progress', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final ch in d.chapters)
                    _ChapterAccordion(
                      chapter: ch,
                      isOpen: _openChapters.contains(ch.chapterId),
                      onToggle: () => _toggle(ch.chapterId),
                    ),

                  const SizedBox(height: 20),

                  if (d.weakTopics.isNotEmpty) ...[
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
                              Text('Weak Topics (${d.weakTopics.length})',
                                  style: AppTypography.labelLarge(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final wt in d.weakTopics)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: c.danger.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(wt.name,
                                            style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                                        Text(wt.chapterName, style: AppTypography.bodySmall(c.textMuted)),
                                      ],
                                    ),
                                  ),
                                  Text('${(wt.masteryScore * 100).round()}%',
                                      style: AppTypography.mono(c.danger, size: 13).copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (d.recommendations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.accentLight,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.lightbulb, size: 15, color: c.accent),
                              const SizedBox(width: 8),
                              Text('Recommendations',
                                  style: AppTypography.labelLarge(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final rec in d.recommendations)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: AppTypography.bodySmall(c.accent)),
                                  Expanded(child: Text(rec, style: AppTypography.bodySmall(c.textPrimary))),
                                ],
                              ),
                            ),
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

class _ChapterAccordion extends StatelessWidget {
  const _ChapterAccordion({required this.chapter, required this.isOpen, required this.onToggle});
  final StudentChapterDetail chapter;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(14),
              color: c.bgCard,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text('${chapter.order}',
                        style: AppTypography.mono(c.textMuted, size: 12).copyWith(fontWeight: FontWeight.w700)),
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
                                  style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(width: 6),
                            if (chapter.status.isNotEmpty) _StatusBadge(chapter.status),
                          ],
                        ),
                        Text('${chapter.coveragePercentage.round()}% covered  •  ${(chapter.masteryScore * 100).round()}% mastery',
                            style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MasteryGauge(value: chapter.masteryScore, size: _GaugeSize.sm),
                  const SizedBox(width: 10),
                  Icon(isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16, color: c.textMuted),
                ],
              ),
            ),
          ),
          if (isOpen && chapter.topics.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(children: [for (final t in chapter.topics) _TopicRow(topic: t)]),
            ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic});
  final StudentTopic topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (stateIcon, stateColor) = switch (topic.state.toUpperCase()) {
      'MASTERED' => (LucideIcons.checkCircle, c.accent),
      'PRACTICING' => (LucideIcons.target, c.textMuted),
      'LEARNING' => (LucideIcons.bookOpen, c.accent),
      'WEAK' => (LucideIcons.triangleAlert, c.danger),
      _ => (LucideIcons.clock, c.textMuted),
    };

    final lastPracticed = topic.lastPracticedAt.isEmpty
        ? 'Never'
        : () {
            final d = DateTime.tryParse(topic.lastPracticedAt);
            return d == null ? topic.lastPracticedAt : d.toLocal().toString().substring(0, 10);
          }();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(stateIcon, size: 16, color: stateColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.name,
                    style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                Text('Last practiced: $lastPracticed', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          _StatusBadge(topic.state),
          const SizedBox(width: 8),
          Text('${(topic.masteryScore * 100).round()}%',
              style: AppTypography.mono(c.textPrimary, size: 12).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
