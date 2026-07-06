part of '../public_pages.dart';

/// `/feedback` — a working feedback form (name, email, message, rating).
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<MarketingFeedbackCubit>();
    if (cubit.name.text.trim().isEmpty || cubit.message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and feedback are required.')));
      return;
    }
    final ok = await cubit.submit();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Thank you for your feedback!' : 'Failed to record feedback.')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MarketingFeedbackCubit>(
      create: (_) => sl<MarketingFeedbackCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<MarketingFeedbackCubit>();
    return BlocBuilder<MarketingFeedbackCubit, FeedbackFormState>(
      builder: (context, state) => _PublicPage(
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(eyebrow: 'FEEDBACK', title: 'Tell us', emphasis: 'more.'),
          const SizedBox(height: 24),
          _input(c, 'Your name', cubit.name, 'Enter your name'),
          const SizedBox(height: 14),
          _input(c, 'Email', cubit.email, 'your@email.com'),
          const SizedBox(height: 14),
          _input(c, 'Message', cubit.message,
              "Tell us what's on your mind... What do you love? What could be better?",
              maxLines: 5),
          const SizedBox(height: 14),
          Text('RATING', style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final filled = i < state.rating;
              return IconButton(
                onPressed: () => cubit.setRating(i + 1),
                icon: Icon(filled ? LucideIcons.star : LucideIcons.star,
                    color: filled ? c.accentSecondary : c.border, size: 24),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.submitting ? null : () => _submit(context),
              style: FilledButton.styleFrom(
                backgroundColor: c.textPrimary, foregroundColor: c.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              child: Text(state.submitting ? 'Sending…' : 'Send feedback',
                  style: AppTypography.button(c.bgPrimary)),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _input(AskAideColors c, String label, TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.bodyLarge(c.textPrimary),
          cursorColor: c.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.bgCard,
            hintText: hint,
            hintStyle: AppTypography.bodyMedium(c.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.accent)),
          ),
        ),
      ],
    );
  }
}
