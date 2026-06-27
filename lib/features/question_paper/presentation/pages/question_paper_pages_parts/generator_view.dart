part of '../question_paper_pages.dart';

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
