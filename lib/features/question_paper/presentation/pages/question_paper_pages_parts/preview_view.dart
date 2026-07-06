part of '../question_paper_pages.dart';

class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.paperId});
  final String paperId;

  Future<void> _printPdf(BuildContext context, PaperPreview preview) async {
    final cubit = context.read<PaperPreviewCubit>();
    cubit.setPrinting(true);
    try {
      // Download the server-rendered PDF (same output as the web app) and hand
      // it to the native share/save sheet.
      final repo = sl<QuestionPaperRepository>();
      final r = await repo.downloadPdf(paperId);
      await r.fold(
        (f) async {
          if (context.mounted) {
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
      cubit.setPrinting(false);
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
        final sections =
            QuestionSectionFactory.groupSections(preview?.questions ?? const []);
        final hasSections = sections.isNotEmpty;
        final sectionOffsets = <int>[
          for (var i = 0, total = 0; i < sections.length; total += sections[i].questions.length, i++)
            total,
        ];
        final ordered = hasSections
            ? [for (final s in sections) ...s.questions]
            : (preview?.questions ?? const []);
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
                              onPressed: (!hasQuestions || state.printing)
                                  ? null
                                  : () => _printPdf(context, preview),
                              icon: state.printing
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
                                  // ---- Sections, one per question type ----
                                  if (hasSections)
                                    for (var s = 0; s < sections.length; s++) ...[
                                      if (s > 0) const SizedBox(height: 12),
                                      Text(sections[s].spec.sectionLabel,
                                          style: AppTypography.labelLarge(
                                              c.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text(sections[s].spec.sectionInstruction,
                                          style: AppTypography.bodySmall(
                                                  c.textMuted)
                                              .copyWith(
                                                  fontStyle: FontStyle.italic)),
                                      const SizedBox(height: 12),
                                      for (var i = 0;
                                          i < sections[s].questions.length;
                                          i++)
                                        _PaperQuestionTile(
                                            index: sectionOffsets[s] + i + 1,
                                            q: sections[s].questions[i],
                                            showOptions:
                                                sections[s].spec.showOptions),
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
                  borderRadius: AppRadii.cardR,
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
