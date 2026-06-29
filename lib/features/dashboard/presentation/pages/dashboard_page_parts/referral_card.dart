part of '../dashboard_page.dart';

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral});
  final ReferralSummary? referral;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasCode = referral != null && referral!.code.isNotEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.accent, c.accentSecondary]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _GradientIcon(LucideIcons.gift, secondary: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Refer a Friend',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                          Text('Both get a streak freeze!',
                              style: AppTypography.bodySmall(c.textSecondary)),
                        ],
                      ),
                    ),
                    if (referral != null && referral!.totalReferrals > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.accentLight,
                          borderRadius: AppRadii.pillR,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.users, size: 13, color: c.accent),
                          const SizedBox(width: 4),
                          Text('${referral!.totalReferrals}',
                              style: AppTypography.mono(c.accent, size: 11)),
                        ]),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (hasCode) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.bgSecondary,
                      borderRadius: AppRadii.sectionR,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your referral code',
                            style: AppTypography.bodySmall(c.textMuted)),
                        const SizedBox(height: 6),
                        DottedBorderBox(
                          color: c.border,
                          child: Center(
                            child: Text(referral!.code,
                                style: AppTypography.mono(c.textPrimary, size: 18)
                                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Invite friends — you both get a streak freeze.',
                        style: AppTypography.bodySmall(c.textMuted)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (hasCode) {
                        Clipboard.setData(ClipboardData(
                          text:
                              '🎯 Join me on AskAide — AI-powered practice for CBSE students! '
                              'Use my referral code: ${referral!.code} and we both get a streak freeze!',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Referral message copied!')),
                        );
                      } else {
                        context.go(RoutePaths.referral);
                      }
                    },
                    icon: const Icon(LucideIcons.share2, size: 15),
                    label: Text(hasCode ? 'Share & Earn' : 'Refer & Earn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A box with a dashed border (for the referral code).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.color});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, radius: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, this.radius = 8});
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
            metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}
