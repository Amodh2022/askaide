part of '../public_pages.dart';

/// `/privacy-policy` and `/terms-of-service` share a sectioned legal layout.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.eyebrow});
  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PublicPage(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(eyebrow: eyebrow, title: title),
          const SizedBox(height: 24),
          for (var i = 1; i <= 4; i++) ...[
            Text('$i. Section heading',
                style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Placeholder legal copy. The full text is provided by AskAide and rendered '
              'here in clear, readable sections.',
              style: AppTypography.bodyMedium(c.textSecondary),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
