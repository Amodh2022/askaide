part of '../public_pages.dart';

/// `/for-schools` — B2B landing: hero, benefits grid, CTA.
class ForSchoolsPage extends StatelessWidget {
  const ForSchoolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const benefits = [
      ['01', 'Daily habit', 'Ten-minute sessions students actually finish.'],
      ['02', 'Measurable', '15–25% score improvement by week six.'],
      ['03', 'Mobile-first', 'Works on ₹8K phones, 80% cached offline.'],
      ['04', 'Zero IT overhead', 'CSV onboarding, no installs, no servers.'],
    ];
    return _PublicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            eyebrow: 'FOR PRINCIPALS & HEADS OF SCHOOL',
            title: 'A daily habit,',
            emphasis: 'measurable.',
            subtitle: 'Adaptive practice that lifts outcomes — at ₹200/student/year.',
          ),
          const SizedBox(height: 24),
          // Content-height cards in a responsive grid (2 cols when wide, else 1)
          // so nothing overflows in portrait or landscape.
          LayoutBuilder(builder: (context, cons) {
            final cols = cons.maxWidth > 520 ? 2 : 1;
            const gap = 12.0;
            final cardWidth = (cons.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final b in benefits)
                  SizedBox(
                    width: cols == 1 ? cons.maxWidth : cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: context.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(b[0], style: AppTypography.mono(c.accent, size: 11)),
                          const SizedBox(height: 6),
                          Text(b[1],
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(b[2], style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openSchoolDemoWhatsApp,
            icon: const Icon(LucideIcons.messageCircle, size: 18, color: Colors.white),
            label: Text('Book a demo on WhatsApp', style: AppTypography.button(Colors.white)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
