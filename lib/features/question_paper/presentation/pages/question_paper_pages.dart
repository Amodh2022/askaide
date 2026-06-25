import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/di/injection.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/question_paper_feature.dart';

/// `/question-paper` — a three-step wizard (Setup → Questions → Options) for
/// generating an exam paper. Mirrors QuestionPaperGenerator's flow.
class QuestionPaperGeneratorPage extends StatelessWidget {
  const QuestionPaperGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<ProfileCubit>().state.user?.id ?? '';
    return BlocProvider<QpGeneratorCubit>(
      create: (_) => sl<QpGeneratorCubit>()..init(teacherId),
      child: const _GeneratorView(),
    );
  }
}

class _GeneratorView extends StatelessWidget {
  const _GeneratorView();

  void _onNext(BuildContext context, QpGenState state) {
    final cubit = context.read<QpGeneratorCubit>();
    if (state.step == 1 && !state.step1Valid) {
      _toast(context, 'Enter a title and pick a subject and class.');
      return;
    }
    if (state.step == 2 && !state.step2Valid) {
      _toast(context, 'Select at least one chapter and one question.');
      return;
    }
    cubit.next();
  }

  void _toast(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<QpGeneratorCubit, QpGenState>(
      listenWhen: (p, n) => p.generatedPaperId != n.generatedPaperId || p.error != n.error,
      listener: (context, state) {
        if (state.generatedPaperId != null && state.generatedPaperId!.isNotEmpty) {
          context.go('/question-paper/preview/${state.generatedPaperId}');
        } else if (state.error != null) {
          _toast(context, state.error!);
        }
      },
      builder: (context, state) {
        final cubit = context.read<QpGeneratorCubit>();

        // While the teacher's assignments load, show shimmering placeholders.
        if (state.loadingAssignments) {
          return const SkeletonListLoader(padding: EdgeInsets.all(24));
        }

        // No subjects/classes assigned — nothing to generate from.
        if (!state.hasAssignments) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: EmptyState(
                icon: LucideIcons.alertCircle,
                title: 'No assignments found',
                hint:
                    "You don't have any class/subject assigned yet. Please contact your admin.",
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: PageHeader(
                          eyebrow: 'PAPERS',
                          title: 'Auto Question',
                          emphasis: 'Paper.',
                          subtitle: state.schoolNamePrefill.isNotEmpty
                              ? state.schoolNamePrefill
                              : null,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/question-paper/history'),
                        icon: Icon(LucideIcons.history, size: 16, color: c.accent),
                        label: Text('History', style: AppTypography.bodyMedium(c.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _StepIndicator(
                    current: state.step,
                    steps: const ['Setup', 'Questions', 'Options'],
                    onTap: (i) {
                      if (i < state.step ||
                          (state.step == 1 && state.step1Valid) ||
                          (state.step == 2 && state.step2Valid)) {
                        cubit.goToStep(i);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.step == 1) ..._step1(context, cubit, state),
                        if (state.step == 2) ..._step2(context, cubit, state),
                        if (state.step == 3) ..._step3(context, cubit, state),
                        const SizedBox(height: 20),
                        Divider(color: c.border),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (state.step > 1)
                              OutlinedButton.icon(
                                onPressed: cubit.back,
                                icon: const Icon(LucideIcons.chevronLeft, size: 16),
                                label: const Text('Back'),
                              ),
                            const Spacer(),
                            if (state.step < 3)
                              FilledButton.icon(
                                onPressed: () => _onNext(context, state),
                                icon: const Icon(LucideIcons.chevronRight, size: 16),
                                label: const Text('Next'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: c.accent, foregroundColor: Colors.white),
                              )
                            else
                              FilledButton.icon(
                                onPressed: state.canGenerate ? cubit.generate : null,
                                icon: state.generating
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(LucideIcons.sparkles, size: 16),
                                label: Text(state.generating ? 'Generating…' : 'Generate Paper'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: c.accent, foregroundColor: Colors.white),
                              ),
                          ],
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

  // ---- Step 1: Paper setup -------------------------------------------------
  List<Widget> _step1(BuildContext context, QpGeneratorCubit cubit, QpGenState state) {
    final c = context.colors;
    return [
      const _SectionTitle(icon: LucideIcons.fileText, label: 'Paper Setup'),
      const SizedBox(height: 16),
      _LabeledField(
        label: 'PAPER TITLE *',
        child: _TextInput(
          value: state.title,
          hint: 'e.g. Mathematics Mid-Term Exam 2026',
          onChanged: cubit.setTitle,
        ),
      ),
      const SizedBox(height: 14),
      _LabeledField(
        label: 'SCHOOL NAME',
        trailing: state.schoolNamePrefill.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Auto-filled',
                    style: AppTypography.bodySmall(c.success)),
              )
            : null,
        child: _TextInput(
          value: state.schoolName,
          hint: 'School name from your profile',
          onChanged: cubit.setSchoolName,
        ),
      ),
      const SizedBox(height: 14),
      _LabeledField(
        label: 'EXAM NAME',
        child: _TextInput(
          value: state.examName,
          hint: 'e.g. Mid-Term Examination',
          onChanged: cubit.setExamName,
        ),
      ),
      const SizedBox(height: 14),
      _LabeledField(
        label: 'DURATION (MINUTES)',
        child: _NumberStepper(
          value: state.duration,
          min: 10,
          max: 300,
          step: 5,
          onChanged: cubit.setDuration,
        ),
      ),
      const SizedBox(height: 14),
      // Subject chip picker — sourced from the teacher's assignments.
      Text('YOUR SUBJECT *', style: AppTypography.mono(c.textMuted, size: 10)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final sub in state.assignments)
            _ChipButton(
              label: sub.subjectName,
              selected: state.subjectId == sub.subjectId,
              onTap: () => cubit.selectSubject(sub.subjectId),
            ),
        ],
      ),
      const SizedBox(height: 14),
      // Class chip picker — only visible once a subject is selected.
      Text('YOUR CLASS *', style: AppTypography.mono(c.textMuted, size: 10)),
      const SizedBox(height: 8),
      if (state.subjectId == null)
        Text('Select a subject first', style: AppTypography.bodySmall(c.textMuted))
      else if (state.classes.isEmpty)
        Text('No classes assigned for this subject',
            style: AppTypography.bodySmall(c.textMuted))
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cls in state.classes)
              _ChipButton(
                label: cls.sections.isEmpty
                    ? cls.className
                    : '${cls.className} (${cls.sections.map((s) => s.name).join(', ')})',
                selected: state.classId == cls.classId,
                onTap: () => cubit.selectClass(cls.classId),
              ),
          ],
        ),
      const SizedBox(height: 4),
      Text('Chapters are selected on the next step.',
          style: AppTypography.bodySmall(c.textMuted)),
    ];
  }

  // ---- Step 2: Chapters + difficulty mix -----------------------------------
  List<Widget> _step2(BuildContext context, QpGeneratorCubit cubit, QpGenState state) {
    final c = context.colors;
    return [
      const _SectionTitle(icon: LucideIcons.bookOpen, label: 'Question Configuration'),
      const SizedBox(height: 16),
      Row(
        children: [
          Text('CHAPTERS *', style: AppTypography.mono(c.textMuted, size: 10)),
          const Spacer(),
          if (state.chapters.isNotEmpty)
            TextButton(
              onPressed: cubit.selectAllChapters,
              child: Text(
                state.chapterIds.length == state.chapters.length
                    ? 'Deselect all'
                    : 'Select all',
                style: AppTypography.bodySmall(c.accent),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (state.chapters.isEmpty)
        Text('No chapters available for this class & subject.',
            style: AppTypography.bodySmall(c.textMuted))
      else
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
                checkmarkColor: c.accent,
              ),
          ],
        ),
      const SizedBox(height: 18),
      Text('QUESTION TYPES', style: AppTypography.mono(c.textMuted, size: 10)),
      const SizedBox(height: 6),
      Row(
        children: [
          for (final t in const [
            ['mcq', 'MCQ'],
            ['fillblanks', 'Fill Blanks'],
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(t[1]),
                selected: state.questionTypes.contains(t[0]),
                onSelected: (_) => cubit.toggleType(t[0]),
                selectedColor: c.accentLight,
                checkmarkColor: c.accent,
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Text('DIFFICULTY MIX', style: AppTypography.mono(c.textMuted, size: 10)),
          const Spacer(),
          Text('Total: ${state.totalQuestions}',
              style: AppTypography.bodySmall(c.accent)),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _DifficultyCounter(
              label: 'Easy', marks: '1 mark', color: c.success,
              value: state.easy, onChanged: cubit.setEasy),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DifficultyCounter(
              label: 'Medium', marks: '2 marks', color: c.warning,
              value: state.medium, onChanged: cubit.setMedium),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DifficultyCounter(
              label: 'Hard', marks: '3 marks', color: c.error,
              value: state.hard, onChanged: cubit.setHard),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.accentLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Estimated total marks', style: AppTypography.bodyMedium(c.textPrimary)),
            Text('${state.estimatedMarks}',
                style: AppTypography.labelLarge(c.accent)),
          ],
        ),
      ),
    ];
  }

  // ---- Step 3: Options -----------------------------------------------------
  List<Widget> _step3(BuildContext context, QpGeneratorCubit cubit, QpGenState state) {
    final c = context.colors;
    return [
      const _SectionTitle(icon: LucideIcons.settings, label: 'Additional Options'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.bgRaised,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Include answer key', style: AppTypography.bodyLarge(c.textPrimary)),
                  Text('Adds an answer key page at the end of the PDF.',
                      style: AppTypography.bodySmall(c.textMuted)),
                ],
              ),
            ),
            Switch(
              value: state.includeAnswerKey,
              activeThumbColor: c.accent,
              onChanged: cubit.setAnswerKey,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('CUSTOM INSTRUCTIONS', style: AppTypography.mono(c.textMuted, size: 10)),
      const SizedBox(height: 8),
      _InstructionAdder(onAdd: cubit.addInstruction),
      if (state.instructions.isNotEmpty) ...[
        const SizedBox(height: 8),
        for (var i = 0; i < state.instructions.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('${i + 1}. ${state.instructions[i]}',
                      style: AppTypography.bodyMedium(c.textPrimary)),
                ),
                InkWell(
                  onTap: () => cubit.removeInstruction(i),
                  child: Icon(LucideIcons.x, size: 16, color: c.error),
                ),
              ],
            ),
          ),
      ],
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.accentLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PAPER SUMMARY', style: AppTypography.mono(c.accent, size: 10)),
            const SizedBox(height: 8),
            _summaryRow(context, 'Title', state.title.isEmpty ? '—' : state.title),
            _summaryRow(context, 'School', state.schoolName.isEmpty ? '—' : state.schoolName),
            _summaryRow(context, 'Subject',
                state.selectedSubjectName.isEmpty ? '—' : state.selectedSubjectName),
            _summaryRow(context, 'Class',
                state.selectedClassName.isEmpty ? '—' : state.selectedClassName),
            _summaryRow(context, 'Chapters', '${state.chapterIds.length}'),
            _summaryRow(context, 'Questions', '${state.totalQuestions}'),
            _summaryRow(context, 'Duration', '${state.duration} min'),
            _summaryRow(context, 'Total marks', '${state.estimatedMarks}'),
            _summaryRow(context, 'Answer key', state.includeAnswerKey ? 'Yes' : 'No'),
          ],
        ),
      ),
    ];
  }

  Widget _summaryRow(BuildContext context, String k, String v) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(k, style: AppTypography.bodySmall(c.textMuted))),
          Expanded(child: Text(v, style: AppTypography.bodyMedium(c.textPrimary))),
        ],
      ),
    );
  }
}

// ---- Wizard helper widgets --------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.steps, required this.onTap});
  final int current;
  final List<String> steps;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: context.cardDecoration(),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: () => onTap(i + 1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: current == i + 1 ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (i + 1) < current ? LucideIcons.circleCheck : LucideIcons.circle,
                        size: 16,
                        color: current == i + 1
                            ? Colors.white
                            : ((i + 1) < current ? c.success : c.textMuted),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          steps[i],
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                              current == i + 1 ? Colors.white : c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: c.accent),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.h3(c.textPrimary)),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.trailing});
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TextInput extends StatefulWidget {
  const _TextInput({required this.value, required this.hint, required this.onChanged});
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _TextInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: _ctrl,
      style: AppTypography.bodyLarge(c.textPrimary),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTypography.bodyMedium(c.textMuted),
        filled: true,
        fillColor: c.bgRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.minus, size: 16),
            onPressed: value - step >= min ? () => onChanged(value - step) : null,
          ),
          SizedBox(
            width: 44,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge(c.textPrimary)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 16),
            onPressed: value + step <= max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _DifficultyCounter extends StatelessWidget {
  const _DifficultyCounter({
    required this.label,
    required this.marks,
    required this.color,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String marks;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.bodyMedium(c.textPrimary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Icon(LucideIcons.minus, size: 14, color: c.textMuted),
              ),
              SizedBox(
                width: 32,
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge(c.textPrimary)),
              ),
              InkWell(
                onTap: () => onChanged(value + 1),
                child: Icon(LucideIcons.plus, size: 14, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(marks, style: AppTypography.bodySmall(c.textMuted)),
        ],
      ),
    );
  }
}

class _InstructionAdder extends StatefulWidget {
  const _InstructionAdder({required this.onAdd});
  final ValueChanged<String> onAdd;
  @override
  State<_InstructionAdder> createState() => _InstructionAdderState();
}

class _InstructionAdderState extends State<_InstructionAdder> {
  final _ctrl = TextEditingController();

  void _add() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onAdd(_ctrl.text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: AppTypography.bodyLarge(c.textPrimary),
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: 'e.g. Use blue/black ink pen only',
              hintStyle: AppTypography.bodyMedium(c.textMuted),
              filled: true,
              fillColor: c.bgRaised,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _add,
          style: FilledButton.styleFrom(
              backgroundColor: c.accent, foregroundColor: Colors.white),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Pill-shaped chip button — accent-filled when selected, outlined otherwise.
class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.bgRaised,
          border: Border.all(color: selected ? c.accent : c.border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(selected ? Colors.white : c.textPrimary),
        ),
      ),
    );
  }
}

class QuestionPaperPreviewPage extends StatelessWidget {
  const QuestionPaperPreviewPage({super.key, required this.paperId});
  final String paperId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaperPreviewCubit>(
      create: (_) => sl<PaperPreviewCubit>()..load(paperId),
      child: _PreviewView(paperId: paperId),
    );
  }
}

class _PreviewView extends StatefulWidget {
  const _PreviewView({required this.paperId});
  final String paperId;
  @override
  State<_PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<_PreviewView> {
  bool _printing = false;

  Future<void> _printPdf(PaperPreview preview) async {
    setState(() => _printing = true);
    try {
      // Download the server-rendered PDF (same output as the web app) and hand
      // it to the native share/save sheet.
      final repo = sl<QuestionPaperRepository>();
      final r = await repo.downloadPdf(widget.paperId);
      await r.fold(
        (f) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to download PDF: ${f.message}')));
          }
        },
        (bytes) => Printing.sharePdf(
          bytes: bytes,
          filename: _pdfFileName(
              preview.examName.isNotEmpty ? preview.examName : preview.title),
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<PaperPreviewCubit, PaperPreviewState>(
      builder: (context, state) {
        final preview = state.preview;
        final hasQuestions = preview != null && preview.questions.isNotEmpty;

        // Split questions into sections matching the PDF / frontend layout.
        final mcqs = preview?.questions
                .where((q) => q.questionType == 'mcq')
                .toList() ??
            const [];
        final fills = preview?.questions
                .where((q) => q.questionType == 'fillblanks')
                .toList() ??
            const [];
        final hasSections = mcqs.isNotEmpty || fills.isNotEmpty;
        final ordered =
            hasSections ? [...mcqs, ...fills] : (preview?.questions ?? const []);
        final hasAnswers =
            ordered.any((q) => q.correctAnswer.isNotEmpty);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar — actions wrap to a new line on narrow widths.
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.go('/question-paper'),
                        icon: Icon(LucideIcons.arrowLeft,
                            size: 16, color: c.textMuted),
                        label: Text('Back',
                            style: AppTypography.bodySmall(c.textMuted)),
                      ),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => context.go('/question-paper'),
                              child: Text('Generate Another',
                                  style: AppTypography.bodySmall(c.accent)),
                            ),
                            FilledButton.icon(
                              onPressed: (!hasQuestions || _printing)
                                  ? null
                                  : () => _printPdf(preview),
                              icon: _printing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(LucideIcons.download, size: 16),
                              label: const Text('Download / Print'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: c.accent,
                                  foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Paper card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow:
                          AppShadows.editorial(Theme.of(context).brightness),
                    ),
                    child: state.status == QpLoad.loading
                        ? const SkeletonListLoader(
                            itemCount: 3, padding: EdgeInsets.all(8))
                        : !hasQuestions
                            ? const EmptyState(
                                icon: LucideIcons.fileText,
                                title: 'No questions',
                                hint:
                                    'This paper has no questions to preview.',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ---- Paper header ----
                                  if (preview.schoolName.isNotEmpty)
                                    Center(
                                      child: Text(
                                        preview.schoolName.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.h2(c.textPrimary)
                                            .copyWith(
                                                fontSize: 16,
                                                letterSpacing: 1.2),
                                      ),
                                    ),
                                  Center(
                                    child: Text(
                                      preview.examName.isNotEmpty
                                          ? preview.examName
                                          : preview.title,
                                      textAlign: TextAlign.center,
                                      style:
                                          AppTypography.h3(c.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Class + Subject
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      children: [
                                        if (preview.className.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.graduationCap,
                                                  size: 13,
                                                  color: c.textMuted),
                                              const SizedBox(width: 4),
                                              Text(preview.className,
                                                  style: AppTypography
                                                      .bodySmall(c.textMuted)),
                                            ],
                                          ),
                                        if (preview.subjectName.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.bookOpen,
                                                  size: 13,
                                                  color: c.textMuted),
                                              const SizedBox(width: 4),
                                              Text(preview.subjectName,
                                                  style: AppTypography
                                                      .bodySmall(c.textMuted)),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Marks + Time
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 16,
                                      children: [
                                        if (preview.totalMarks > 0)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.award,
                                                  size: 13,
                                                  color: c.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                  'Total Marks: ${preview.totalMarks}',
                                                  style: AppTypography
                                                      .bodySmall(c.textMuted)),
                                            ],
                                          ),
                                        if (preview.duration > 0)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.clock,
                                                  size: 13,
                                                  color: c.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                  'Time: ${preview.duration} min',
                                                  style: AppTypography
                                                      .bodySmall(c.textMuted)),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(color: c.border),
                                  const SizedBox(height: 16),
                                  // ---- Instructions ----
                                  if (preview.instructions.isNotEmpty) ...[
                                    Text('General Instructions',
                                        style: AppTypography.labelLarge(
                                            c.textPrimary)),
                                    const SizedBox(height: 8),
                                    for (var i = 0;
                                        i < preview.instructions.length;
                                        i++)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 3),
                                        child: Text(
                                          '${i + 1}. ${preview.instructions[i]}',
                                          style: AppTypography.bodySmall(
                                              c.textMuted),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Divider(color: c.border),
                                    const SizedBox(height: 16),
                                  ],
                                  // ---- Section A — MCQ ----
                                  if (hasSections && mcqs.isNotEmpty) ...[
                                    Text(
                                        'Section A — Multiple Choice Questions',
                                        style: AppTypography.labelLarge(
                                            c.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Answer all questions. Choose the correct option.',
                                        style:
                                            AppTypography.bodySmall(c.textMuted)
                                                .copyWith(
                                                    fontStyle:
                                                        FontStyle.italic)),
                                    const SizedBox(height: 12),
                                    for (var i = 0; i < mcqs.length; i++)
                                      _PaperQuestionTile(
                                          index: i + 1, q: mcqs[i]),
                                  ],
                                  // ---- Section B — Fill Blanks ----
                                  if (hasSections && fills.isNotEmpty) ...[
                                    if (mcqs.isNotEmpty)
                                      const SizedBox(height: 12),
                                    Text('Section B — Fill in the Blanks',
                                        style: AppTypography.labelLarge(
                                            c.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Fill in the blanks with the correct answer.',
                                        style:
                                            AppTypography.bodySmall(c.textMuted)
                                                .copyWith(
                                                    fontStyle:
                                                        FontStyle.italic)),
                                    const SizedBox(height: 12),
                                    for (var i = 0; i < fills.length; i++)
                                      _PaperQuestionTile(
                                          index: mcqs.length + i + 1,
                                          q: fills[i],
                                          showOptions: false),
                                  ],
                                  // ---- Flat list (no type info) ----
                                  if (!hasSections)
                                    for (var i = 0;
                                        i < preview.questions.length;
                                        i++)
                                      _PaperQuestionTile(
                                          index: i + 1,
                                          q: preview.questions[i]),
                                  // ---- Answer Key ----
                                  if (preview.includeAnswerKey &&
                                      hasAnswers) ...[
                                    const SizedBox(height: 24),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(top: 16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                              color: c.border,
                                              style: BorderStyle.solid),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Answer Key',
                                              style: AppTypography.labelLarge(
                                                  c.textPrimary)),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              for (var i = 0;
                                                  i < ordered.length;
                                                  i++)
                                                if (ordered[i]
                                                    .correctAnswer
                                                    .isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: c.accentLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      'Q${i + 1}: ${ordered[i].correctAnswer}',
                                                      style: AppTypography.mono(
                                                          c.accent,
                                                          size: 11),
                                                    ),
                                                  ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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

/// Builds a safe PDF filename from a paper title, mirroring React's
/// `` `${title}.pdf`.replace(/[^a-zA-Z0-9.\-_ ]/g, '') ``.
String _pdfFileName(String title) {
  final base = title.trim().isEmpty ? 'question-paper' : title.trim();
  final safe = base.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_ ]'), '');
  return '$safe.pdf';
}

/// Opens the system print/share sheet for a generated [preview] with an answer
/// key included. Used by the public/guest generator to download its PDF.
Future<void> printPaperPdf(PaperPreview preview, {bool withAnswers = true}) {
  return Printing.layoutPdf(
    name: preview.examName.isNotEmpty ? preview.examName : preview.title,
    onLayout: (format) async => _buildPdf(preview, format, withAnswers),
  );
}

/// Builds the printable PDF for a question paper. Renders a header (school /
/// exam / meta), general instructions, MCQ + fill-in-blank sections and an
/// optional answer key. Mirrors the React public PDF layout.
Future<Uint8List> _buildPdf(PaperPreview preview, PdfPageFormat format, bool withAnswers) async {
  const marks = {'Easy': 1, 'Medium': 2, 'Hard': 3};
  final doc = pw.Document();

  pw.Widget questionBlock(int displayNo, PaperQuestion q, {bool showOptions = true}) {
    final m = marks[q.difficulty] ?? 1;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text('Q$displayNo. ${q.text}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('[$m Mark${m > 1 ? 's' : ''}]',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          if (showOptions && q.options.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            for (var o = 0; o < q.options.length; o++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                child: pw.Text('(${String.fromCharCode(97 + o)}) ${q.options[o]}',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
          ],
        ],
      ),
    );
  }

  final mcqs = preview.questions.where((q) => q.questionType == 'mcq').toList();
  final fills = preview.questions.where((q) => q.questionType == 'fillblanks').toList();
  // Fall back to flat numbering when there is no type info on questions.
  final hasSections = mcqs.isNotEmpty || fills.isNotEmpty;
  final ordered = hasSections ? [...mcqs, ...fills] : preview.questions;

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      build: (ctx) => [
        if (preview.schoolName.isNotEmpty)
          pw.Center(
            child: pw.Text(preview.schoolName.toUpperCase(),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
        pw.Center(
          child: pw.Text(
              preview.examName.isNotEmpty ? preview.examName : preview.title,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            [
              if (preview.duration > 0) 'Time: ${preview.duration} min',
              if (preview.totalMarks > 0) 'Total Marks: ${preview.totalMarks}',
            ].join('   |   '),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Divider(),
        if (preview.instructions.isNotEmpty) ...[
          pw.Text('General Instructions:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          for (var i = 0; i < preview.instructions.length; i++)
            pw.Text('${i + 1}. ${preview.instructions[i]}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
        ],
        if (hasSections) ...[
          if (mcqs.isNotEmpty) ...[
            pw.Text('Section A — Multiple Choice Questions',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            for (var i = 0; i < mcqs.length; i++) questionBlock(i + 1, mcqs[i]),
          ],
          if (fills.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Section B — Fill in the Blanks',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            for (var i = 0; i < fills.length; i++)
              questionBlock(mcqs.length + i + 1, fills[i], showOptions: false),
          ],
        ] else
          for (var i = 0; i < ordered.length; i++) questionBlock(i + 1, ordered[i]),
        if (withAnswers) ...[
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Text('Answer Key',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          for (var i = 0; i < ordered.length; i++)
            if (ordered[i].correctAnswer.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('Q${i + 1}: ${ordered[i].correctAnswer}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
              ),
        ],
      ],
    ),
  );
  return doc.save();
}

/// One question tile — number + text + marks badge + options (if MCQ).
class _PaperQuestionTile extends StatelessWidget {
  const _PaperQuestionTile({
    required this.index,
    required this.q,
    this.showOptions = true,
  });
  final int index;
  final PaperQuestion q;
  final bool showOptions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final marks = switch (q.difficulty.toLowerCase()) {
      'medium' => 2,
      'hard' => 3,
      _ => 1,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Q$index. ${q.text}',
                  style: AppTypography.bodyLarge(c.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[$marks Mark${marks > 1 ? 's' : ''}]',
                  style: AppTypography.mono(c.textMuted, size: 9),
                ),
              ),
            ],
          ),
          if (showOptions && q.options.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 3),
                child: Text(
                  '(${String.fromCharCode(97 + i)}) ${q.options[i]}',
                  style: AppTypography.bodyMedium(c.textSecondary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// `/question-paper/history` — archive of generated papers, loaded live.
class QuestionPaperHistoryPage extends StatelessWidget {
  const QuestionPaperHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaperHistoryCubit>(
      create: (_) => sl<PaperHistoryCubit>()..load(),
      child: const _PaperHistoryView(),
    );
  }
}

class _PaperHistoryView extends StatefulWidget {
  const _PaperHistoryView();
  @override
  State<_PaperHistoryView> createState() => _PaperHistoryViewState();
}

class _PaperHistoryViewState extends State<_PaperHistoryView> {
  String? _downloadingId;
  String? _deletingId;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _download(PaperSummary p) async {
    setState(() => _downloadingId = p.id);
    try {
      // Fetch the server-rendered PDF (matches the web download) and share it.
      final repo = sl<QuestionPaperRepository>();
      final r = await repo.downloadPdf(p.id);
      await r.fold(
        (f) async => _snack('Failed to download PDF: ${f.message}'),
        (bytes) => Printing.sharePdf(
          bytes: bytes,
          filename: _pdfFileName(p.title),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _confirmDelete(PaperSummary p) async {
    final cubit = context.read<PaperHistoryCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete paper?'),
        content: Text('"${p.title}" will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deletingId = p.id);
    final success = await cubit.delete(p.id);
    if (!mounted) return;
    setState(() => _deletingId = null);
    _snack(success ? 'Paper deleted' : 'Failed to delete paper');
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour12 =
        d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final mm = d.minute.toString().padLeft(2, '0');
    final amPm = d.hour < 12 ? 'AM' : 'PM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}, $hour12:$mm $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<PaperHistoryCubit, PaperHistoryState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon badge + title + count + Generate New button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.fileText,
                            size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paper History',
                                style: AppTypography.h2(c.textPrimary)
                                    .copyWith(fontSize: 22)),
                            Text(
                              state.total > 0
                                  ? '${state.total} papers generated'
                                  : 'Your generated papers',
                              style: AppTypography.bodySmall(c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.go('/question-paper'),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Generate New'),
                        style: FilledButton.styleFrom(
                            backgroundColor: c.accent,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Content
                  if (state.status == QpLoad.loading)
                    const SkeletonListLoader(padding: EdgeInsets.all(24))
                  else if (state.papers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 24),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.alertCircle,
                              size: 40, color: c.textMuted),
                          const SizedBox(height: 12),
                          Text('No papers generated yet',
                              style: AppTypography.h4(c.textPrimary)),
                          const SizedBox(height: 8),
                          Text('Create your first AI-generated question paper.',
                              style: AppTypography.bodySmall(c.textMuted),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.go('/question-paper'),
                            style: FilledButton.styleFrom(
                                backgroundColor: c.accent,
                                foregroundColor: Colors.white),
                            child: const Text('Generate First Paper'),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final p in state.papers)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.bgCard,
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + date
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelLarge(
                                            c.textPrimary),
                                      ),
                                    ),
                                    if (_formatDate(p.createdAt).isNotEmpty)
                                      Text(
                                        _formatDate(p.createdAt),
                                        style: AppTypography.mono(c.textMuted,
                                            size: 10),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Class + Subject chips
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (p.className.isNotEmpty)
                                      _HistoryChip(p.className,
                                          fg: c.accent, bg: c.accentLight),
                                    if (p.subjectName.isNotEmpty)
                                      _HistoryChip(p.subjectName,
                                          fg: const Color(0xFF3B82F6),
                                          bg: const Color(0xFFEFF6FF)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Stats
                                Text(
                                  [
                                    '${p.questionCount} Q',
                                    if (p.totalMarks > 0)
                                      '${p.totalMarks} marks',
                                    if (p.duration > 0) '${p.duration} min',
                                  ].join(' · '),
                                  style: AppTypography.bodySmall(c.textMuted),
                                ),
                                const SizedBox(height: 12),
                                // Action row: Eye + Download + Delete
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => context.go(
                                          '/question-paper/preview/${p.id}'),
                                      icon: const Icon(LucideIcons.eye,
                                          size: 14),
                                      label: const Text('Preview'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.textMuted,
                                        side: BorderSide(color: c.border),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle:
                                            AppTypography.bodySmall(c.textMuted),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _downloadingId == p.id
                                          ? null
                                          : () => _download(p),
                                      icon: _downloadingId == p.id
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 1.5))
                                          : const Icon(LucideIcons.download,
                                              size: 14),
                                      label: const Text('Download'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.success,
                                        side: BorderSide(color: c.success),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle:
                                            AppTypography.bodySmall(c.success),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _deletingId == p.id
                                          ? null
                                          : () => _confirmDelete(p),
                                      icon: _deletingId == p.id
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 1.5))
                                          : const Icon(LucideIcons.trash2,
                                              size: 14),
                                      label: const Text('Delete'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.error,
                                        side: BorderSide(color: c.error),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle:
                                            AppTypography.bodySmall(c.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        // Pagination
                        if (state.totalPages > 1) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: state.page > 1
                                    ? () => context
                                        .read<PaperHistoryCubit>()
                                        .load(page: state.page - 1)
                                    : null,
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Page ${state.page} of ${state.totalPages}',
                                style: AppTypography.mono(c.textMuted, size: 11),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: state.page < state.totalPages
                                    ? () => context
                                        .read<PaperHistoryCubit>()
                                        .load(page: state.page + 1)
                                    : null,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ],
                      ],
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

/// Colored pill chip for class/subject labels on history cards.
class _HistoryChip extends StatelessWidget {
  const _HistoryChip(this.label, {required this.fg, required this.bg});
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: AppTypography.bodySmall(fg).copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
