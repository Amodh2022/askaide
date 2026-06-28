part of '../role_dashboard_pages.dart';

class _TeacherHomeView extends StatelessWidget {
  const _TeacherHomeView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    final today = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
      builder: (context, state) {
        final data = state.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEACHER DASHBOARD', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 6),
                  Text('Your class, today.',
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (data.teacherName.isNotEmpty) data.teacherName,
                      if (data.schoolName.isNotEmpty) data.schoolName,
                      today,
                    ].join(' · '),
                    style: AppTypography.bodySmall(c.textMuted),
                  ),
                  const SizedBox(height: 20),

                  if (state.status == TLoad.loading) ...[
                    const _TeacherHomeSkeleton(),
                  ] else ...[
                    // Quick actions
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionButton(
                          label: 'Quizzes',
                          icon: LucideIcons.clipboardList,
                          onTap: () => context.go('/teacher/quizzes'),
                          filled: true,
                        ),
                        _ActionButton(
                          label: 'Question Papers',
                          icon: LucideIcons.fileText,
                          onTap: () => context.go('/question-paper'),
                        ),
                        _ActionButton(
                          label: 'AI Generator',
                          icon: LucideIcons.sparkles,
                          onTap: () => context.go('/teacher/ai-generator'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.accentLight,
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${data.assignments.length}',
                                  style: AppTypography.mono(c.accent, size: 12).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('Subjects', style: AppTypography.bodySmall(c.accent)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.accentLight,
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${data.totalStudentsAcrossSubjects}',
                                  style: AppTypography.mono(c.accent, size: 12).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('Students', style: AppTypography.bodySmall(c.accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (data.assignments.isEmpty)
                      Container(
                        width: double.infinity,
                        decoration: context.cardDecoration(),
                        child: const EmptyState(
                          icon: LucideIcons.users,
                          title: 'No assigned subjects',
                          hint: 'Subjects assigned to you by an admin will appear here.',
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Icon(LucideIcons.bookOpen, size: 16, color: c.accent),
                          const SizedBox(width: 8),
                          Text('My Subjects',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Responsive grid: two columns on tablet+ widths, single
                      // column on phones (mirrors React's md:grid-cols-2).
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 12.0;
                          final twoCol = constraints.maxWidth >= 640;
                          final cardW = twoCol
                              ? (constraints.maxWidth - gap) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final a in data.assignments)
                                SizedBox(
                                    width: cardW, child: _SubjectCard(assignment: a)),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.assignment});
  final TeacherAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final emoji = _subjectEmoji(assignment.subjectName);
    return GestureDetector(
      onTap: () => context.go('/teacher/subject/${assignment.subjectId}'),
      child: Container(
        decoration: context.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: double.infinity,
              color: c.accentLight,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.users, size: 11, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('${assignment.totalStudents}',
                            style: AppTypography.mono(c.textMuted, size: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.subjectName,
                      style: AppTypography.labelLarge(c.textPrimary).copyWith(fontSize: 17)),
                  const SizedBox(height: 6),
                  for (final cls in assignment.classes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(LucideIcons.graduationCap, size: 13, color: c.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${cls.className}${cls.sections.isNotEmpty ? ' · ${cls.sections.map((s) => s.name).join(', ')} sections' : ''}',
                              style: AppTypography.bodySmall(c.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('View Dashboard',
                          style: AppTypography.bodySmall(c.accent).copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight, size: 13, color: c.accent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
