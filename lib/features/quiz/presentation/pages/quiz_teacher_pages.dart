import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/quiz_models.dart';
import '../quiz_teacher_cubits.dart';

/// `/teacher/quizzes` — the teacher's quizzes with status + actions.
class TeacherQuizListPage extends StatelessWidget {
  const TeacherQuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherQuizListCubit>(
      create: (_) => sl<TeacherQuizListCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? ''),
      child: const _TeacherQuizListView(),
    );
  }
}

class _TeacherQuizListView extends StatelessWidget {
  const _TeacherQuizListView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                      child: PageHeader(
                          eyebrow: 'TEACHER',
                          title: 'My',
                          emphasis: 'quizzes.')),
                  FilledButton.icon(
                    onPressed: () => context.go('/teacher/quiz/new'),
                    icon: const Icon(LucideIcons.plus,
                        size: 16, color: Colors.white),
                    label: Text('Create',
                        style: AppTypography.button(Colors.white)),
                    style: FilledButton.styleFrom(backgroundColor: c.accent),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              BlocBuilder<TeacherQuizListCubit, TeacherQuizListState>(
                builder: (context, state) {
                  if (state.status == TqLoad.loading) {
                    return const SkeletonListLoader(padding: EdgeInsets.all(24));
                  }
                  if (state.quizzes.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: const EmptyState(
                        icon: LucideIcons.listChecks,
                        title: 'No quizzes yet',
                        hint: 'Create your first quiz with the button above.',
                      ),
                    );
                  }
                  final cubit = context.read<TeacherQuizListCubit>();
                  return Column(
                    children: [
                      for (final q in state.quizzes)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: context.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(q.title,
                                          style: AppTypography.h4(c.textPrimary)
                                              .copyWith(fontSize: 17))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: c.accentLight,
                                        borderRadius:
                                            BorderRadius.circular(99)),
                                    child: Text(q.status.toUpperCase(),
                                        style: AppTypography.mono(c.accent,
                                            size: 9)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${q.questionCount} questions',
                                  style: AppTypography.bodySmall(c.textMuted)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                      onPressed: () => context.go(
                                          '/teacher/quiz/${q.id}/questions'),
                                      child: const Text('Questions')),
                                  TextButton(
                                      onPressed: () => context.go(
                                          '/teacher/quiz/${q.id}/analytics'),
                                      child: const Text('Analytics')),
                                  if (q.status == 'draft')
                                    TextButton(
                                        onPressed: () => cubit.publish(q.id),
                                        child: const Text('Publish'))
                                  else if (q.status == 'published')
                                    TextButton(
                                        onPressed: () => cubit.closeQuiz(q.id),
                                        child: const Text('Close')),
                                  TextButton(
                                      onPressed: () => cubit.clone(q.id),
                                      child: const Text('Clone')),
                                  TextButton(
                                      onPressed: () => cubit.remove(q.id),
                                      child: Text('Delete',
                                          style: TextStyle(color: c.danger))),
                                ],
                              ),
                            ],
                          ),
                        ),
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

/// `/teacher/quiz/new` — create a quiz (title + class/subject/chapters + time).
class QuizFormPage extends StatelessWidget {
  const QuizFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBuilderCubit>(
      create: (_) => sl<QuizBuilderCubit>()..init(),
      child: const _QuizFormView(),
    );
  }
}

class _QuizFormView extends StatefulWidget {
  const _QuizFormView();
  @override
  State<_QuizFormView> createState() => _QuizFormViewState();
}

const _showAnswersOptions = <(String, String)>[
  ('immediately', 'Immediately after answering'),
  ('submission', 'After quiz submission'),
  ('deadline', 'After deadline passes'),
  ('never', 'Never show answers'),
];

class _QuizFormViewState extends State<_QuizFormView> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _timeLimit = 30;
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;
  String _showAnswersAfter = 'submission';
  int _allowedAttempts = 1;
  int _passingPercentage = 50;
  DateTime? _deadline;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (!mounted) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<QuizBuilderCubit, QuizBuilderState>(
      listenWhen: (p, n) => p.createdQuizId != n.createdQuizId,
      listener: (context, state) {
        if (state.createdQuizId != null) {
          context.go('/teacher/quiz/${state.createdQuizId}/questions');
        }
      },
      builder: (context, state) {
        final cubit = context.read<QuizBuilderCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/quizzes'),
                    child: Text('← Quizzes',
                        style: AppTypography.bodySmall(c.textMuted)),
                  ),
                  const SizedBox(height: 12),
                  const PageHeader(
                      eyebrow: 'TEACHER', title: 'New', emphasis: 'quiz.'),
                  const SizedBox(height: 20),
                  _field(c, 'Title', _title, 'e.g. Chapter 3 Quiz'),
                  const SizedBox(height: 12),
                  _field(c, 'Description', _desc, 'Optional'),
                  const SizedBox(height: 12),
                  _dropdown(
                      c,
                      'Class',
                      state.classId,
                      state.classes.map((e) => (e.id, e.name)).toList(),
                      cubit.selectClass),
                  const SizedBox(height: 12),
                  _dropdown(
                      c,
                      'Subject',
                      state.subjectId,
                      state.subjects.map((e) => (e.id, e.name)).toList(),
                      cubit.selectSubject),
                  const SizedBox(height: 12),
                  if (state.chapters.isNotEmpty) ...[
                    Text('CHAPTERS',
                        style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final ch in state.chapters)
                          FilterChip(
                            label: Text(ch.name),
                            selected: state.chapterIds.contains(ch.id),
                            onSelected: (_) => cubit.toggleChapter(ch.id),
                            selectedColor: c.accentLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text('SETTINGS',
                      style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 8),
                  Text('TIME LIMIT: $_timeLimit min',
                      style: AppTypography.mono(c.textMuted, size: 10)),
                  Slider(
                    value: _timeLimit.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: c.accent,
                    label: '$_timeLimit',
                    onChanged: (v) => setState(() => _timeLimit = v.round()),
                  ),
                  const SizedBox(height: 4),
                  Text('PASSING %: $_passingPercentage%',
                      style: AppTypography.mono(c.textMuted, size: 10)),
                  Slider(
                    value: _passingPercentage.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: c.accent,
                    label: '$_passingPercentage',
                    onChanged: (v) =>
                        setState(() => _passingPercentage = v.round()),
                  ),
                  const SizedBox(height: 4),
                  Text('ALLOWED ATTEMPTS: $_allowedAttempts',
                      style: AppTypography.mono(c.textMuted, size: 10)),
                  Slider(
                    value: _allowedAttempts.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: c.accent,
                    label: '$_allowedAttempts',
                    onChanged: (v) =>
                        setState(() => _allowedAttempts = v.round()),
                  ),
                  const SizedBox(height: 12),
                  _dropdown(
                    c,
                    'Show answers',
                    _showAnswersAfter,
                    _showAnswersOptions,
                    (v) => setState(() => _showAnswersAfter = v),
                  ),
                  const SizedBox(height: 12),
                  Text('DEADLINE',
                      style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDeadline,
                          icon: const Icon(LucideIcons.calendar, size: 16),
                          label: Text(
                            _deadline == null
                                ? 'No deadline'
                                : _deadline!
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                            style: AppTypography.bodyMedium(c.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.textPrimary,
                            side: BorderSide(color: c.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        IconButton(
                          onPressed: () => setState(() => _deadline = null),
                          icon:
                              Icon(LucideIcons.x, size: 16, color: c.textMuted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: c.accent,
                    value: _shuffleQuestions,
                    onChanged: (v) => setState(() => _shuffleQuestions = v),
                    title: Text('Shuffle questions',
                        style: AppTypography.bodyMedium(c.textPrimary)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: c.accent,
                    value: _shuffleOptions,
                    onChanged: (v) => setState(() => _shuffleOptions = v),
                    title: Text('Shuffle options',
                        style: AppTypography.bodyMedium(c.textPrimary)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (state.classId != null &&
                              state.subjectId != null &&
                              !state.creating)
                          ? () => cubit.create(
                                _title.text.trim(),
                                _desc.text.trim(),
                                QuizSettingsDraft(
                                  timeLimit: _timeLimit,
                                  shuffleQuestions: _shuffleQuestions,
                                  shuffleOptions: _shuffleOptions,
                                  showAnswersAfter: _showAnswersAfter,
                                  allowedAttempts: _allowedAttempts,
                                  passingPercentage: _passingPercentage,
                                  deadline: _deadline,
                                ),
                              )
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.textPrimary,
                        foregroundColor: c.bgPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: state.creating
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: c.bgPrimary))
                          : Text('Create & add questions',
                              style: AppTypography.button(c.bgPrimary)),
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

  Widget _field(AskAideColors c, String label, TextEditingController ctl,
          String hint) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          TextField(
            controller: ctl,
            style: AppTypography.bodyLarge(c.textPrimary),
            cursorColor: c.accent,
            decoration: InputDecoration(
              filled: true,
              fillColor: c.bgRaised,
              hintText: hint,
              hintStyle: AppTypography.bodyMedium(c.textMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.accent)),
            ),
          ),
        ],
      );

  Widget _dropdown(AskAideColors c, String label, String? value,
          List<(String, String)> items, ValueChanged<String> onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgRaised,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text('Select $label',
                    style: AppTypography.bodyMedium(c.textMuted)),
                dropdownColor: c.bgCard,
                style: AppTypography.bodyLarge(c.textPrimary),
                items: [
                  for (final it in items)
                    DropdownMenuItem(value: it.$1, child: Text(it.$2))
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      );
}

/// `/teacher/quiz/:quizId/questions` — search the bank and add questions.
class QuizQuestionManagerPage extends StatelessWidget {
  const QuizQuestionManagerPage({super.key, required this.quizId});
  final String quizId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBuilderCubit>(
      create: (_) => sl<QuizBuilderCubit>()
        ..init()
        ..loadQuiz(quizId),
      child: _QuizQuestionManagerView(quizId: quizId),
    );
  }
}

class _QuizQuestionManagerView extends StatelessWidget {
  const _QuizQuestionManagerView({required this.quizId});
  final String quizId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<QuizBuilderCubit, QuizBuilderState>(
      builder: (context, state) {
        final cubit = context.read<QuizBuilderCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/quizzes'),
                    child: Text('← Quizzes',
                        style: AppTypography.bodySmall(c.textMuted)),
                  ),
                  const SizedBox(height: 12),
                  const PageHeader(
                      eyebrow: 'TEACHER', title: 'Add', emphasis: 'questions.'),
                  const SizedBox(height: 16),
                  if (state.loadingManaged || state.managed.isNotEmpty) ...[
                    _ManagedQuestions(quizId: quizId),
                    const SizedBox(height: 24),
                    Text('ADD MORE FROM THE QUESTION BANK',
                        style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: 8),
                  ],
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final cls in state.classes)
                      ChoiceChip(
                          label: Text(cls.name),
                          selected: state.classId == cls.id,
                          onSelected: (_) => cubit.selectClass(cls.id)),
                  ]),
                  if (state.subjects.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final s in state.subjects)
                        ChoiceChip(
                            label: Text(s.name),
                            selected: state.subjectId == s.id,
                            onSelected: (_) => cubit.selectSubject(s.id)),
                    ]),
                  ],
                  if (state.chapters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final ch in state.chapters)
                        FilterChip(
                            label: Text(ch.name),
                            selected: state.chapterIds.contains(ch.id),
                            onSelected: (_) => cubit.toggleChapter(ch.id),
                            selectedColor: c.accentLight),
                    ]),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: state.chapterIds.isEmpty ? null : cubit.search,
                      style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: Colors.white),
                      child: Text(state.searching
                          ? 'Searching…'
                          : 'Search question bank'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (final q in state.bank)
                    CheckboxListTile(
                      value: state.selectedQuestionIds.contains(q.id),
                      onChanged: (_) => cubit.toggleQuestion(q.id),
                      activeColor: c.accent,
                      title: Text(q.text,
                          style: AppTypography.bodyMedium(c.textPrimary)),
                      subtitle: Text('${q.difficulty} • ${q.type}',
                          style: AppTypography.bodySmall(c.textMuted)),
                    ),
                  if (state.selectedOrder.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('SELECTED — SET MARKS & DRAG TO REORDER',
                        style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: 8),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: state.selectedOrder.length,
                      itemBuilder: (context, index) {
                        final id = state.selectedOrder[index];
                        final q = state.bank.firstWhere(
                          (e) => e.id == id,
                          orElse: () => const BankQuestion(
                              id: '',
                              text: '',
                              options: [],
                              difficulty: '',
                              type: ''),
                        );
                        return Container(
                          key: ValueKey(id),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: context.cardDecoration(),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(LucideIcons.gripVertical,
                                    size: 16, color: c.textMuted),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: c.accentLight,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text('${index + 1}',
                                    style:
                                        AppTypography.mono(c.accent, size: 11)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(q.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium(
                                        c.textPrimary)),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 56,
                                child: TextFormField(
                                  initialValue: '${state.marksById[id] ?? 1}',
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style:
                                      AppTypography.bodyMedium(c.textPrimary),
                                  cursorColor: c.accent,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Marks',
                                    labelStyle: AppTypography.mono(c.textMuted,
                                        size: 9),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide:
                                            BorderSide(color: c.border)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide:
                                            BorderSide(color: c.accent)),
                                  ),
                                  onChanged: (v) =>
                                      cubit.setMarks(id, int.tryParse(v) ?? 1),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onReorder: cubit.reorderSelected,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final ok = await cubit.addSelectedTo(quizId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(ok
                                          ? 'Questions added to the quiz'
                                          : 'Could not add')));
                            }
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: c.textPrimary,
                              foregroundColor: c.bgPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder()),
                          child: Text(
                              'Add ${state.selectedOrder.length} questions',
                              style: AppTypography.button(c.bgPrimary)),
                        ),
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

/// The questions already attached to the quiz: drag to reorder, trash to
/// remove. Mirrors React `QuizQuestionManager`'s existing-question list.
class _ManagedQuestions extends StatelessWidget {
  const _ManagedQuestions({required this.quizId});
  final String quizId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<QuizBuilderCubit>();
    final state = context.watch<QuizBuilderCubit>().state;

    if (state.loadingManaged && state.managed.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 180, height: 14),
              SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 12),
              SizedBox(height: 8),
              SkeletonBox(width: 240, height: 12),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUESTIONS IN THIS QUIZ — DRAG TO REORDER',
            style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: state.managed.length,
          itemBuilder: (context, index) {
            final q = state.managed[index];
            return Container(
              key: ValueKey(q.id),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: context.cardDecoration(),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(LucideIcons.gripVertical,
                        size: 16, color: c.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: c.accentLight,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('${index + 1}',
                        style: AppTypography.mono(c.accent, size: 11)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(q.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(c.textPrimary)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: c.accentLight,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('${q.marks} mark${q.marks == 1 ? '' : 's'}',
                        style: AppTypography.mono(c.accent, size: 10)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove',
                    icon: Icon(LucideIcons.trash2, size: 16, color: c.danger),
                    onPressed: () => _confirmRemove(context, cubit, q),
                  ),
                ],
              ),
            );
          },
          onReorder: (int oldIndex, int newIndex) =>
              cubit.reorderManaged(quizId, oldIndex, newIndex),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, QuizBuilderCubit cubit,
      QuizManagedQuestion q) async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove question?', style: AppTypography.h4(c.textPrimary)),
        content: Text(q.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium(c.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppTypography.button(c.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: c.danger, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.removeManaged(quizId, q.id);
  }
}

/// `/teacher/quiz/:quizId/analytics` — quiz performance overview.
class QuizAnalyticsPage extends StatelessWidget {
  const QuizAnalyticsPage({super.key, required this.quizId});
  final String quizId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizAnalyticsCubit>(
      create: (_) => sl<QuizAnalyticsCubit>()..load(quizId),
      child: const _QuizAnalyticsView(),
    );
  }
}

class _QuizAnalyticsView extends StatelessWidget {
  const _QuizAnalyticsView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<QuizAnalyticsCubit, QuizAnalyticsState>(
      builder: (context, state) {
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
                    onTap: () => context.go('/teacher/quizzes'),
                    child: Text('← Quizzes',
                        style: AppTypography.bodySmall(c.textMuted)),
                  ),
                  const SizedBox(height: 12),
                  const PageHeader(
                      eyebrow: 'TEACHER',
                      title: 'Quiz',
                      emphasis: 'analytics.'),
                  const SizedBox(height: 20),
                  if (state.status == TqLoad.loading)
                    const SkeletonListLoader(itemCount: 3, padding: EdgeInsets.all(8))
                  else ...[
                    Row(
                      children: [
                        _stat(context, '${d.totalAttempts}', 'ATTEMPTS'),
                        const SizedBox(width: 12),
                        _stat(context, '${d.avgScore.round()}', 'AVG SCORE'),
                        const SizedBox(width: 12),
                        _stat(context, '${d.passRate.round()}%', 'PASS RATE'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _questionAnalysis(context, d),
                    const SizedBox(height: 24),
                    _studentLists(context, d),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext context, String v, String l) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(),
        child: Column(children: [
          Text(v, style: AppTypography.statNumber(c.accent, size: 26)),
          const SizedBox(height: 4),
          Text(l, style: AppTypography.mono(c.textMuted, size: 10)),
        ]),
      ),
    );
  }

  Color _rateColor(AskAideColors c, double pct) =>
      pct >= 70 ? c.success : (pct >= 40 ? c.warning : c.danger);

  Widget _questionAnalysis(BuildContext context, QuizAnalyticsData d) {
    final c = context.colors;
    final qs = d.questionAnalysis;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.chartColumn, size: 16, color: c.accent),
            const SizedBox(width: 8),
            Text('QUESTION-BY-QUESTION',
                style: AppTypography.mono(c.textMuted, size: 10)),
          ]),
          const SizedBox(height: 16),
          if (qs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No question data yet',
                    style: AppTypography.bodyMedium(c.textMuted)),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= qs.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                                'Q${qs[i].order > 0 ? qs[i].order : i + 1}',
                                style:
                                    AppTypography.mono(c.textMuted, size: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < qs.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: qs[i].correctPercentage.clamp(0, 100),
                          color: _rateColor(c, qs[i].correctPercentage),
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < qs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                          color: _rateColor(c, qs[i].correctPercentage),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${qs[i].questionText}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium(c.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            '${qs[i].correctPercentage.round()}% correct • ${qs[i].totalAttempts} attempts • ${qs[i].marks} mark${qs[i].marks > 1 ? 's' : ''}',
                            style: AppTypography.bodySmall(c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _studentLists(BuildContext context, QuizAnalyticsData d) {
    final top = _studentCard(
      context,
      icon: LucideIcons.award,
      iconColor: context.colors.warning,
      title: 'TOP PERFORMERS',
      students: d.topPerformers,
      emptyText: 'No completed attempts yet',
      totalMarks: d.totalMarks,
    );
    final struggling = _studentCard(
      context,
      icon: LucideIcons.triangleAlert,
      iconColor: context.colors.danger,
      title: 'NEEDS ATTENTION',
      students: d.strugglingStudents,
      emptyText: 'All students performing well!',
      totalMarks: d.totalMarks,
    );
    if (context.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: top),
          const SizedBox(width: 12),
          Expanded(child: struggling),
        ],
      );
    }
    return Column(children: [top, const SizedBox(height: 12), struggling]);
  }

  Widget _studentCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<QuizStudentStat> students,
    required String emptyText,
    required int totalMarks,
  }) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.mono(c.textMuted, size: 10)),
          ]),
          const SizedBox(height: 12),
          if (students.isEmpty)
            Text(emptyText, style: AppTypography.bodySmall(c.textMuted))
          else
            for (final s in students.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium(c.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      totalMarks > 0
                          ? '${s.score}/$totalMarks (${s.percentage.round()}%)'
                          : '${s.percentage.round()}%',
                      style: AppTypography.mono(c.textMuted, size: 11),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
