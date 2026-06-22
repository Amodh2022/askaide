import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/taxonomy/taxonomy_repository.dart';
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
    return BlocProvider<QpGeneratorCubit>(
      create: (_) => sl<QpGeneratorCubit>()..init(),
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
                      const Expanded(
                        child: PageHeader(eyebrow: 'PAPERS', title: 'Generate a', emphasis: 'paper.'),
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
        child: _TextInput(
          value: state.schoolName,
          hint: 'School name',
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
      _Picker(
        label: 'CLASS *',
        hint: 'Select class',
        value: state.classId,
        items: state.classes,
        onChanged: cubit.selectClass,
      ),
      const SizedBox(height: 14),
      _Picker(
        label: 'SUBJECT *',
        hint: state.classId == null ? 'Select class first' : 'Select subject',
        value: state.subjectId,
        items: state.subjects,
        onChanged: cubit.selectSubject,
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
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
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

class _Picker extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final String? value;
  final List<TaxItem> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
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
              hint: Text(hint, style: AppTypography.bodyMedium(c.textMuted)),
              dropdownColor: c.bgCard,
              style: AppTypography.bodyLarge(c.textPrimary),
              items: [
                for (final it in items)
                  DropdownMenuItem(value: it.id, child: Text(it.name)),
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
  bool _showAnswers = false;
  bool _printing = false;

  Future<void> _printPdf(PaperPreview preview) async {
    setState(() => _printing = true);
    try {
      await Printing.layoutPdf(
        name: preview.title,
        onLayout: (format) async => _buildPdf(preview, format, _showAnswers),
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
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.go('/question-paper'),
                        icon: Icon(LucideIcons.arrowLeft, size: 16, color: c.textMuted),
                        label: Text('Back', style: AppTypography.bodySmall(c.textMuted)),
                      ),
                      const Spacer(),
                      // Answer-key toggle
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Answer key', style: AppTypography.bodySmall(c.textMuted)),
                          Switch(
                            value: _showAnswers,
                            activeThumbColor: c.accent,
                            onChanged: (v) => setState(() => _showAnswers = v),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: (!hasQuestions || _printing) ? null : () => _printPdf(preview),
                        icon: _printing
                            ? const SizedBox(
                                width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.download, size: 16),
                        label: const Text('Download / Print'),
                        style: FilledButton.styleFrom(
                            backgroundColor: c.accent, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: AppShadows.editorial(Theme.of(context).brightness),
                    ),
                    child: Column(
                      children: [
                        Text(preview?.title ?? 'Question Paper',
                            style: AppTypography.h3(c.textPrimary), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Divider(color: c.border),
                        const SizedBox(height: 16),
                        if (state.status == QpLoad.loading)
                          const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator())
                        else if (!hasQuestions)
                          const EmptyState(
                            icon: LucideIcons.fileText,
                            title: 'No questions',
                            hint: 'This paper has no questions to preview.',
                          )
                        else
                          for (var i = 0; i < preview.questions.length; i++)
                            _PaperQuestionRow(
                                index: i, q: preview.questions[i], showAnswer: _showAnswers),
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
                    style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
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
                style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
        pw.Center(
          child: pw.Text(
              preview.examName.isNotEmpty ? preview.examName : preview.title,
              style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
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
              style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          for (var i = 0; i < preview.instructions.length; i++)
            pw.Text('${i + 1}. ${preview.instructions[i]}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
        ],
        if (hasSections) ...[
          if (mcqs.isNotEmpty) ...[
            pw.Text('Section A — Multiple Choice Questions',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            for (var i = 0; i < mcqs.length; i++) questionBlock(i + 1, mcqs[i]),
          ],
          if (fills.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Section B — Fill in the Blanks',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
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
              style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
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

class _PaperQuestionRow extends StatelessWidget {
  const _PaperQuestionRow({required this.index, required this.q, this.showAnswer = false});
  final int index;
  final PaperQuestion q;
  final bool showAnswer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q${index + 1}. ${q.text}',
              style: AppTypography.bodyLarge(c.textPrimary)),
          const SizedBox(height: 6),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text('${String.fromCharCode(65 + i)}. ${q.options[i]}',
                  style: AppTypography.bodyMedium(c.textSecondary)),
            ),
          if (showAnswer && q.correctAnswer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text('Answer: ${q.correctAnswer}',
                  style: AppTypography.bodySmall(c.success)),
            ),
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
      final repo = sl<QuestionPaperRepository>();
      final r = await repo.preview(p.id);
      await r.fold(
        (f) async => _snack('Failed to load paper: ${f.message}'),
        (preview) => Printing.layoutPdf(
          name: preview.title.isEmpty ? p.title : preview.title,
          onLayout: (format) async => _buildPdf(preview, format, true),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.colors.error),
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
              const PageHeader(eyebrow: 'PAPERS', title: 'Paper', emphasis: 'history.'),
              const SizedBox(height: 24),
              BlocBuilder<PaperHistoryCubit, PaperHistoryState>(
                builder: (context, state) {
                  if (state.status == QpLoad.loading) {
                    return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (state.papers.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: const EmptyState(
                        icon: LucideIcons.history,
                        title: 'No papers yet',
                        hint: 'Papers you generate will be listed here.',
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in state.papers)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: context.cardDecoration(),
                          child: Row(
                            children: [
                              Icon(LucideIcons.fileText, color: c.accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.go('/question-paper/preview/${p.id}'),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.title,
                                          style: AppTypography.labelLarge(c.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          if (p.className.isNotEmpty) p.className,
                                          if (p.subjectName.isNotEmpty) p.subjectName,
                                          '${p.questionCount} Q',
                                          if (p.totalMarks > 0) '${p.totalMarks} marks',
                                          if (p.duration > 0) '${p.duration} min',
                                        ].join(' · '),
                                        style: AppTypography.bodySmall(c.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Download PDF',
                                onPressed: _downloadingId == p.id ? null : () => _download(p),
                                icon: _downloadingId == p.id
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(LucideIcons.download, size: 18, color: c.success),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: _deletingId == p.id ? null : () => _confirmDelete(p),
                                icon: _deletingId == p.id
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(LucideIcons.trash2, size: 18, color: c.error),
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
