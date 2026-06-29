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

class _PublicPaperGeneratorView extends StatefulWidget {
  const _PublicPaperGeneratorView();
  @override
  State<_PublicPaperGeneratorView> createState() => _PublicPaperGeneratorViewState();
}

class _PublicPaperGeneratorViewState extends State<_PublicPaperGeneratorView> {
  bool _downloading = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _onNext(PublicQpState s) {
    final cubit = context.read<PublicQpCubit>();
    if (s.step == 1) {
      if (!s.step1Valid) {
        _snack('Please select a class and subject.');
        return;
      }
      cubit.next();
    } else if (s.step == 2) {
      if (!s.step2Valid) {
        _snack('Please select at least one chapter.');
        return;
      }
      cubit.generate();
    }
  }

  Future<void> _download(PublicQpState s) async {
    if (!s.leadValid) {
      _snack('Please enter your name, school and a valid email/WhatsApp.');
      return;
    }
    final paper = s.paper;
    if (paper == null) return;
    setState(() => _downloading = true);
    try {
      await printPaperPdf(paper);
      _snack('PDF ready.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PublicQpCubit, PublicQpState>(
      listenWhen: (p, n) => p.error != n.error && n.error != null,
      listener: (context, state) => _snack(state.error!),
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
        _PubStepIndicator(current: s.step, steps: const ['Class & Subject', 'Chapters']),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.step == 1) ...[
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
              if (s.step == 2) ...[
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
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      for (final ch in s.chapters)
                        FilterChip(
                          label: Text(ch.name),
                          selected: s.chapterIds.contains(ch.id),
                          onSelected: (_) => cubit.toggleChapter(ch.id),
                          selectedColor: c.accentLight,
                          checkmarkColor: c.accent,
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Text('DEMO — 10 questions · MCQ & fill-in-blank · answer key included',
                    style: AppTypography.mono(c.textMuted, size: 9)),
              ],
              const SizedBox(height: 20),
              Divider(color: c.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (s.step > 1)
                    OutlinedButton.icon(
                      onPressed: cubit.back,
                      icon: const Icon(LucideIcons.chevronLeft, size: 16),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: s.generating ? null : () => _onNext(s),
                    icon: s.generating
                        ? const BtnSpinner(size: 16)
                        : Icon(s.step < 2 ? LucideIcons.chevronRight : LucideIcons.fileText, size: 16),
                    label: Text(s.generating
                        ? 'Generating…'
                        : (s.step < 2 ? 'Continue' : 'Generate paper')),
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
                onPressed: _downloading ? null : () => _download(s),
                icon: _downloading
                    ? const BtnSpinner(size: 16)
                    : const Icon(LucideIcons.download, size: 16),
                label: Text(_downloading ? 'Preparing PDF…' : 'Download PDF'),
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

class _PubStepIndicator extends StatelessWidget {
  const _PubStepIndicator({required this.current, required this.steps});
  final int current;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: context.cardDecoration(),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: current == i + 1 ? c.accent : Colors.transparent,
                  borderRadius: AppRadii.cardR,
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
                      child: Text(steps[i],
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                              current == i + 1 ? Colors.white : c.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
          borderRadius: AppRadii.cardR,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.cardR,
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}
