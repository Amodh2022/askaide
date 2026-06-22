import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../ai_assistant/ai_assistant_repository.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../parent/parent_feature.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/teacher_feature.dart';

/// `/teacher` — class analytics hub. Loads the teacher's subject assignments
/// live; each opens a subject dashboard (`/teacher/subject/:id`).
class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherHomeCubit>(
      create: (_) => sl<TeacherHomeCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? ''),
      child: const _TeacherHomeView(),
    );
  }
}

class _TeacherHomeView extends StatelessWidget {
  const _TeacherHomeView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                eyebrow: 'TEACHER',
                title: 'Class',
                emphasis: 'analytics.',
                subtitle: 'Track mastery, spot at-risk students, and manage quizzes.',
              ),
              const SizedBox(height: 24),
              BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
                builder: (context, state) {
                  if (state.status == TLoad.loading) {
                    return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (state.assignments.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: const EmptyState(
                        icon: LucideIcons.users,
                        title: 'No assigned subjects',
                        hint: 'Subjects assigned to you by an admin will appear here.',
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: context.cardDecoration(),
                        child: ListTile(
                          onTap: () => context.go('/teacher/quizzes'),
                          leading: Icon(LucideIcons.listChecks, color: c.accent),
                          title: Text('Manage quizzes',
                              style: AppTypography.labelLarge(c.textPrimary)),
                          subtitle: Text('Create, publish, and analyze quizzes',
                              style: AppTypography.bodySmall(c.textMuted)),
                          trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
                        ),
                      ),
                      Text('Your subjects',
                          style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                      const SizedBox(height: 12),
                      for (final a in state.assignments)
                        _AssignmentCard(assignment: a),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});
  final TeacherAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: context.cardDecoration(),
      child: ListTile(
        onTap: () => context.go('/teacher/subject/${assignment.subjectId}'),
        leading: Icon(LucideIcons.bookOpen, color: c.accent),
        title: Text(assignment.subjectName, style: AppTypography.labelLarge(c.textPrimary)),
        subtitle: Text(
            '${assignment.className.isEmpty ? '' : '${assignment.className} • '}${assignment.studentCount} students',
            style: AppTypography.bodySmall(c.textMuted)),
        trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      ),
    );
  }
}

/// `/teacher/subject/:subjectId` — class overview + students + weak topics.
class TeacherSubjectPage extends StatelessWidget {
  const TeacherSubjectPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherSubjectCubit>(
      create: (_) => sl<TeacherSubjectCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', subjectId),
      child: _TeacherSubjectView(subjectId: subjectId),
    );
  }
}

enum _StudentSort { mastery, name, questions }

class _TeacherSubjectView extends StatefulWidget {
  const _TeacherSubjectView({required this.subjectId});
  final String subjectId;
  @override
  State<_TeacherSubjectView> createState() => _TeacherSubjectViewState();
}

class _TeacherSubjectViewState extends State<_TeacherSubjectView> {
  _StudentSort _sort = _StudentSort.mastery;
  String _statusFilter = 'all';

  List<StudentRow> _applySortFilter(List<StudentRow> students) {
    var list = students;
    if (_statusFilter != 'all') {
      list = list.where((s) => _statusKey(s) == _statusFilter).toList();
    }
    list = [...list];
    switch (_sort) {
      case _StudentSort.mastery:
        list.sort((a, b) => b.mastery.compareTo(a.mastery));
      case _StudentSort.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _StudentSort.questions:
        list.sort((a, b) => b.questionsAttempted.compareTo(a.questionsAttempted));
    }
    return list;
  }

  static String _statusKey(StudentRow s) {
    final st = s.status.toLowerCase();
    if (st.contains('strug') || st.contains('risk') || st.contains('weak')) return 'struggling';
    if (st.contains('top') || st.contains('strong')) return 'top';
    if (st.contains('inactive') || st.contains('idle')) return 'inactive';
    return s.mastery >= 0.7 ? 'top' : (s.mastery < 0.4 ? 'struggling' : 'active');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherSubjectCubit, TeacherSubjectState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = state.dashboard;
        final students = _applySortFilter(state.students);
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
                    child: Text('← Teacher', style: AppTypography.bodySmall(c.textMuted)),
                  ),
                  const SizedBox(height: 12),
                  PageHeader(
                      eyebrow: 'SUBJECT',
                      title: d.subjectName.isEmpty ? 'Subject' : d.subjectName,
                      emphasis: 'overview.'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _Overview(value: '${d.studentCount}', label: 'STUDENTS'),
                      const SizedBox(width: 12),
                      _Overview(value: '${(d.avgMastery * 100).round()}%', label: 'AVG MASTERY'),
                      const SizedBox(width: 12),
                      _Overview(value: '${(d.avgCoverage * 100).round()}%', label: 'COVERAGE'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Students header + sort/filter controls
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 10,
                    children: [
                      Text('Students', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Pill<String>(
                            value: _statusFilter,
                            items: const [
                              ('all', 'All'),
                              ('struggling', 'Struggling'),
                              ('top', 'Top'),
                              ('inactive', 'Inactive'),
                            ],
                            onChanged: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _Pill<_StudentSort>(
                            value: _sort,
                            items: const [
                              (_StudentSort.mastery, 'Mastery'),
                              (_StudentSort.name, 'Name'),
                              (_StudentSort.questions, 'Questions'),
                            ],
                            onChanged: (v) => setState(() => _sort = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (students.isEmpty)
                    Text('No students match.', style: AppTypography.bodyMedium(c.textMuted))
                  else
                    for (final s in students) _StudentRowCard(student: s, subjectId: widget.subjectId),
                  const SizedBox(height: 24),
                  Text('Weak topics', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  if (state.weakTopics.isEmpty)
                    Text('No weak topics flagged.', style: AppTypography.bodyMedium(c.textMuted))
                  else
                    for (final w in state.weakTopics)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: context.cardDecoration(),
                        child: Row(
                          children: [
                            Icon(LucideIcons.triangleAlert, size: 16, color: c.warning),
                            const SizedBox(width: 10),
                            Expanded(child: Text(w.name, style: AppTypography.bodyMedium(c.textPrimary))),
                            if (w.studentCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Text('${w.studentCount} students',
                                    style: AppTypography.bodySmall(c.textMuted)),
                              ),
                            Text('${(w.mastery * 100).round()}%',
                                style: AppTypography.mono(c.danger, size: 13)),
                          ],
                        ),
                      ),
                  const SizedBox(height: 24),
                  Text('Recent activity', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  if (state.activity.isEmpty)
                    Text('No recent activity.', style: AppTypography.bodyMedium(c.textMuted))
                  else
                    for (final a in state.activity.take(15))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(LucideIcons.activity, size: 14, color: c.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${a.studentName} ${a.action}',
                                  style: AppTypography.bodySmall(c.textSecondary)),
                            ),
                            Text(_relativeTime(a.timestamp),
                                style: AppTypography.mono(c.textMuted, size: 10)),
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

String _relativeTime(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

/// A small segmented pill selector used for sort/filter controls.
class _Pill<T> extends StatelessWidget {
  const _Pill({required this.value, required this.items, required this.onChanged});
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: c.bgCard,
          icon: Icon(LucideIcons.chevronDown, size: 14, color: c.textMuted),
          style: AppTypography.bodySmall(c.textPrimary),
          items: [for (final it in items) DropdownMenuItem(value: it.$1, child: Text(it.$2))],
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

/// A student row with a status badge, question count, and mastery.
class _StudentRowCard extends StatelessWidget {
  const _StudentRowCard({required this.student, required this.subjectId});
  final StudentRow student;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final key = _TeacherSubjectViewState._statusKey(student);
    final (badgeColor, badgeLabel) = switch (key) {
      'struggling' => (c.danger, 'Struggling'),
      'top' => (c.accent, 'Top'),
      'inactive' => (c.textMuted, 'Inactive'),
      _ => (c.warning, 'Active'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: context.cardDecoration(),
      child: ListTile(
        onTap: () => context.go('/teacher/subject/$subjectId/student/${student.id}'),
        title: Text(student.name, style: AppTypography.bodyMedium(c.textPrimary)),
        subtitle: Text('${student.questionsAttempted} questions',
            style: AppTypography.bodySmall(c.textMuted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(badgeLabel, style: AppTypography.mono(badgeColor, size: 9)),
            ),
            const SizedBox(width: 10),
            Text('${(student.mastery * 100).round()}%',
                style: AppTypography.mono(c.accent, size: 13)),
          ],
        ),
      ),
    );
  }
}

/// `/parent` — family oversight. Loads the parent's children and the first
/// child's overview (streak, mastery) from the live API.
class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParentCubit>(
      create: (_) => sl<ParentCubit>()..load(),
      child: const _ParentView(),
    );
  }
}

class _ParentView extends StatelessWidget {
  const _ParentView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final ov = state.overview;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    eyebrow: 'PARENT',
                    title: 'Family',
                    emphasis: 'oversight.',
                    subtitle: "Follow your child's practice, streaks, and mastery.",
                  ),
                  const SizedBox(height: 24),
                  if (state.status == PLoad.loading)
                    const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()))
                  else if (state.children.isEmpty)
                    Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: const EmptyState(
                        icon: LucideIcons.users,
                        title: 'No linked children',
                        hint: 'Children linked to your account will appear here.',
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        _Overview(value: '${ov?.streakDays ?? 0}', label: 'STREAK'),
                        const SizedBox(width: 12),
                        _Overview(
                            value: ov == null ? '—' : '${(ov.overallMastery * 100).round()}%',
                            label: 'MASTERY'),
                        const SizedBox(width: 12),
                        _Overview(value: '${state.children.length}', label: 'CHILDREN'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Children', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                    const SizedBox(height: 8),
                    for (final child in state.children)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: context.cardDecoration(),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: c.accentLight,
                            child: Icon(LucideIcons.user, color: c.accent, size: 18),
                          ),
                          title: Text(child.name, style: AppTypography.labelLarge(c.textPrimary)),
                          subtitle: child.grade.isEmpty
                              ? null
                              : Text(child.grade, style: AppTypography.bodySmall(c.textMuted)),
                        ),
                      ),
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

class _Overview extends StatelessWidget {
  const _Overview({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Expands to share row width evenly and avoid overflow on narrow screens.
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTypography.statNumber(c.accent, size: 28)),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.mono(c.textMuted, size: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}


/// `/teacher/subject/:subjectId/student/:studentId` — one student's progress.
class TeacherStudentPage extends StatelessWidget {
  const TeacherStudentPage({super.key, required this.subjectId, required this.studentId});
  final String subjectId;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherStudentCubit>(
      create: (_) => sl<TeacherStudentCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', studentId, subjectId),
      child: _TeacherStudentView(subjectId: subjectId),
    );
  }
}

class _TeacherStudentView extends StatelessWidget {
  const _TeacherStudentView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherStudentCubit, TeacherStudentState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = state.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/$subjectId'),
                    child: Text('← Subject', style: AppTypography.bodySmall(c.textMuted)),
                  ),
                  const SizedBox(height: 12),
                  PageHeader(
                      eyebrow: 'STUDENT',
                      title: d.studentName.isEmpty ? 'Student' : d.studentName,
                      emphasis: 'progress.'),
                  const SizedBox(height: 16),
                  Row(children: [
                    _Overview(value: '${(d.overallMastery * 100).round()}%', label: 'MASTERY'),
                    const SizedBox(width: 12),
                    _Overview(value: '${d.chapters.length}', label: 'CHAPTERS'),
                  ]),
                  const SizedBox(height: 20),
                  for (final ch in d.chapters)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: context.cardDecoration(),
                      child: Row(
                        children: [
                          Expanded(child: Text(ch.name, style: AppTypography.bodyMedium(c.textPrimary))),
                          Text('${(ch.mastery * 100).round()}%',
                              style: AppTypography.mono(c.accent, size: 13)),
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

/// `/teacher/ai-generator` — a prompt box wired to the AI assistant.
class TeacherAiGeneratorPage extends StatefulWidget {
  const TeacherAiGeneratorPage({super.key});
  @override
  State<TeacherAiGeneratorPage> createState() => _TeacherAiGeneratorPageState();
}

class _TeacherAiGeneratorPageState extends State<TeacherAiGeneratorPage> {
  final _prompt = TextEditingController();
  String? _answer;
  bool _loading = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_prompt.text.trim().isEmpty) return;
    setState(() { _loading = true; _answer = null; });
    final r = await sl<AiAssistantRepository>().ask(_prompt.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _answer = r.fold((f) => 'Error: ${f.message}', (a) => a);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                  eyebrow: 'TEACHER', title: 'AI', emphasis: 'generator.',
                  subtitle: 'Ask the assistant to generate questions, notes, or explanations.'),
              const SizedBox(height: 20),
              TextField(
                controller: _prompt,
                maxLines: 4,
                style: AppTypography.bodyLarge(c.textPrimary),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.bgCard,
                  hintText: 'e.g. Generate 5 medium MCQs on photosynthesis',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.accent)),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _go,
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                child: Text(_loading ? 'Generating…' : 'Generate'),
              ),
              if (_answer != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: context.cardDecoration(),
                  child: MarkdownBody(data: _answer!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
