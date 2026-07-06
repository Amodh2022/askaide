part of '../role_dashboard_pages.dart';

class _TeacherAiGeneratorView extends StatelessWidget {
  const _TeacherAiGeneratorView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<TeacherAiGeneratorCubit>();
    final state = context.watch<TeacherAiGeneratorCubit>().state;
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
                controller: cubit.prompt,
                maxLines: 4,
                style: AppTypography.bodyLarge(c.textPrimary),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.bgCard,
                  hintText: 'e.g. Generate 5 medium MCQs on photosynthesis',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.accent)),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.loading ? null : cubit.generate,
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                child: Text(state.loading ? 'Generating…' : 'Generate'),
              ),
              if (state.answer != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: context.cardDecoration(),
                  child: MarkdownBody(data: state.answer!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
