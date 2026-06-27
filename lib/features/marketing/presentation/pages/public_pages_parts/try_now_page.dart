part of '../public_pages.dart';

/// `/try` — guest practice teaser (three free questions).
class TryNowPage extends StatelessWidget {
  const TryNowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PublicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            eyebrow: 'FREE TRIAL',
            title: 'Try three',
            emphasis: 'questions.',
            subtitle: 'No account needed. Pick a chapter and feel the difference.',
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: context.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready when you are', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Start a free session — we\'ll ask one question at a time and adapt to you.',
                    style: AppTypography.bodyMedium(c.textMuted)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(RoutePaths.signup),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  child: const Text('Start free practice →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
