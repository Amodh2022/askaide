part of '../public_pages.dart';

/// `/free-paper-generator` — real guest paper generation (lead magnet).
/// A two-step flow (Class & Subject → Chapters) generates a sample paper via the
/// public endpoint, then captures the lead's details before letting them
/// download the PDF. Mirrors React's PublicPaperGenerator.
class PublicPaperGeneratorPage extends StatelessWidget {
  const PublicPaperGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PublicQpCubit>(
      create: (_) => sl<PublicQpCubit>()..init(),
      child: const _PublicPaperGeneratorView(),
    );
  }
}

class _PublicPaperGeneratorView extends StatelessWidget {
  const _PublicPaperGeneratorView();

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _onNext(BuildContext context, PublicQpState s) {
    final cubit = context.read<PublicQpCubit>();
    if (!s.step.isValid(s)) {
      _snack(context, s.step.validationMessage);
      return;
    }
    if (s.step.ordinal == publicQpWizardSteps.length - 1) {
      cubit.generate();
    } else {
      cubit.next();
    }
  }

  Future<void> _download(BuildContext context, PublicQpState s) async {
    if (!s.leadValid) {
      _snack(context, 'Please enter your name, school and a valid email/WhatsApp.');
      return;
    }
    final paper = s.paper;
    if (paper == null) return;
    final cubit = context.read<PublicQpCubit>();
    cubit.setDownloading(true);
    try {
      await printPaperPdf(paper);
      if (context.mounted) _snack(context, 'PDF ready.');
    } finally {
      cubit.setDownloading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PublicQpCubit, PublicQpState>(
      listenWhen: (p, n) => p.error != n.error && n.error != null,
      listener: (context, state) => _snack(context, state.error!),
      builder: (context, state) {
        return _PublicPage(
          child: state.stage == PubGenStage.ready
              ? _readyView(context, state)
              : _setupView(context, state),
        );
      },
    );
  }

  // ---- Setup (steps 1 & 2) -------------------------------------------------
  Widget _setupView(BuildContext context, PublicQpState s) {
    final c = context.colors;
    final cubit = context.read<PublicQpCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          eyebrow: 'FREE PAPER GENERATOR · CBSE · ICSE · STATE',
          title: 'A paper in',
          emphasis: 'seconds.',
          subtitle:
              'Select class, subject and chapters. AI builds the paper — MCQs, '
              'fill-in-the-blanks, answer key included. No account needed.',
        ),
        const SizedBox(height: 20),
        StepIndicator(
          current: s.step.ordinal + 1,
          steps: publicQpWizardSteps.map((e) => e.label).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...switch (s.step) {
                PublicClassSubjectStep() => [
                    Text('SELECT CLASS', style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        for (final cls in s.classes)
                          ChoiceChip(
                            label: Text(cls.name),
                            selected: s.classId == cls.id,
                            onSelected: (_) => cubit.selectClass(cls.id),
                            selectedColor: c.accentLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('SELECT SUBJECT', style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: 8),
                    if (s.classId == null)
                      Text('Select a class first.', style: AppTypography.bodySmall(c.textMuted))
                    else
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          for (final sub in s.subjects)
                            ChoiceChip(
                              label: Text(sub.name),
                              selected: s.subjectId == sub.id,
                              onSelected: (_) => cubit.selectSubject(sub.id),
                              selectedColor: c.accentLight,
                            ),
                        ],
                      ),
                  ],
                PublicChaptersStep() => [
                    Row(
                      children: [
                        Text('SELECT CHAPTERS', style: AppTypography.mono(c.textMuted, size: 10)),
                        const Spacer(),
                        if (s.chapters.isNotEmpty)
                          TextButton(
                            onPressed: cubit.selectAllChapters,
                            child: Text(
                              s.chapterIds.length == s.chapters.length
                                  ? 'Deselect all'
                                  : 'Select all',
                              style: AppTypography.bodySmall(c.accent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (s.chapters.isEmpty)
                      Text('No chapters available for this subject yet.',
                          style: AppTypography.bodySmall(c.textMuted))
                    else
                      ChipPicker<TaxItem>(
                        items: s.chapters,
                        isSelected: (ch) => s.chapterIds.contains(ch.id),
                        onToggle: (ch) => cubit.toggleChapter(ch.id),
                        labelOf: (ch) => ch.name,
                      ),
                    const SizedBox(height: 12),
                    Text('DEMO — 10 questions · MCQ & fill-in-blank · answer key included',
                        style: AppTypography.mono(c.textMuted, size: 9)),
                  ],
              },
              const SizedBox(height: 20),
              Divider(color: c.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (s.step.ordinal > 0)
                    OutlinedButton.icon(
                      onPressed: cubit.back,
                      icon: const Icon(LucideIcons.chevronLeft, size: 16),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: s.generating ? null : () => _onNext(context, s),
                    icon: s.generating
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(
                            s.step.ordinal < publicQpWizardSteps.length - 1
                                ? LucideIcons.chevronRight
                                : LucideIcons.fileText,
                            size: 16),
                    label: Text(s.generating
                        ? 'Generating…'
                        : (s.step.ordinal < publicQpWizardSteps.length - 1
                            ? 'Continue'
                            : 'Generate paper')),
                    style: FilledButton.styleFrom(
                        backgroundColor: c.accent, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Ready (lead capture + download) -------------------------------------
  Widget _readyView(BuildContext context, PublicQpState s) {
    final c = context.colors;
    final cubit = context.read<PublicQpCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          eyebrow: 'PAPER READY',
          title: 'Your paper is',
          emphasis: 'ready.',
          subtitle: '10 questions · answer key included.',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('YOUR DETAILS · TO DOWNLOAD',
                  style: AppTypography.mono(c.textMuted, size: 10)),
              const SizedBox(height: 12),
              _PubTextField(hint: 'Full name', onChanged: cubit.setName),
              const SizedBox(height: 10),
              _PubTextField(hint: 'School name', onChanged: cubit.setSchoolName),
              const SizedBox(height: 10),
              _PubTextField(
                  hint: 'WhatsApp number or email', onChanged: cubit.setContactInfo),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.lock, size: 12, color: c.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text("No spam. We'll send a backup to your contact.",
                        style: AppTypography.mono(c.textMuted, size: 9)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: s.downloading ? null : () => _download(context, s),
                icon: s.downloading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.download, size: 16),
                label: Text(s.downloading ? 'Preparing PDF…' : 'Download PDF'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FOR SCHOOLS', style: AppTypography.mono(c.textMuted, size: 10)),
              const SizedBox(height: 8),
              Text('One account. Unlimited papers.',
                  style: AppTypography.h3(c.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Teacher dashboard, difficulty control, saved history and '
                'class-level analytics.',
                style: AppTypography.bodyMedium(c.textMuted),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => context.go(RoutePaths.signup),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent, foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                child: const Text('Create school account →'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PubTextField extends StatelessWidget {
  const _PubTextField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      onChanged: onChanged,
      style: AppTypography.bodyLarge(c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
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
