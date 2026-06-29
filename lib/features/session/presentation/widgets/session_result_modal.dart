import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/session_bloc.dart';

/// Shows the end-of-session summary dialog (mirrors React's SessionResultModal):
/// an animated score, correct / wrong / accuracy stats, and a performance
/// message keyed to the percentage. Completes when the user dismisses it.
Future<void> showSessionResultModal(
  BuildContext context,
  SessionSummary summary,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _SessionResultModal(summary: summary),
  );
}

class _SessionResultModal extends StatelessWidget {
  const _SessionResultModal({required this.summary});
  final SessionSummary summary;

  ({String message, String emoji}) _config(int pct) {
    if (pct >= 80) return (message: 'Excellent work!', emoji: '🏆');
    if (pct >= 50) return (message: 'Good effort! Keep practicing', emoji: '🎉');
    return (message: "You're learning! Try again", emoji: '💪');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = summary.accuracyPercent;
    final cfg = _config(pct);

    return Dialog(
      backgroundColor: c.bgCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.modalR),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header band
            Container(
              height: 96,
              width: double.infinity,
              color: pct >= 80 ? c.accent : c.textPrimary,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: AppRadii.modalR,
                    ),
                    child: const Icon(LucideIcons.trophy,
                        size: 32, color: Colors.white),
                  ),
                  Positioned(
                    top: 10,
                    right: 18,
                    child: Text(cfg.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.accentLight,
                      borderRadius: AppRadii.pillR,
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 12, color: c.accent),
                        const SizedBox(width: 6),
                        Text(cfg.message.toUpperCase(),
                            style: AppTypography.mono(c.accent, size: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text("You've completed the practice session!",
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(c.textSecondary)),
                  const SizedBox(height: AppSpacing.md),
                  // Animated score
                  _AnimatedScore(score: summary.score, total: summary.total),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('QUESTIONS CORRECT',
                      style: AppTypography.mono(c.textMuted, size: 9)),
                  const SizedBox(height: 20),
                  // Stat row
                  Row(
                    children: [
                      _stat(context, LucideIcons.circleCheck, c.accent,
                          '${summary.score}', 'CORRECT'),
                      const SizedBox(width: AppSpacing.xs),
                      _stat(context, LucideIcons.circleX, c.danger,
                          '${summary.incorrect}', 'WRONG'),
                      const SizedBox(width: AppSpacing.xs),
                      _stat(context, LucideIcons.target, c.accent,
                          '$pct%', 'SCORE'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.textPrimary,
                        foregroundColor: c.bgPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.cardR),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.house, size: 18, color: c.bgPrimary),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Done', style: AppTypography.button(c.bgPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, Color iconColor,
      String value, String label) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: c.bgSecondary,
          border: Border.all(color: c.border),
          borderRadius: AppRadii.cardR,
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.mono(c.textSecondary, size: 8)),
          ],
        ),
      ),
    );
  }
}

/// Counts the score up with an ease-out curve, like React's RAF animation.
class _AnimatedScore extends StatelessWidget {
  const _AnimatedScore({required this.score, required this.total});
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return RichText(
          text: TextSpan(
            text: '${value.round()}',
            style: AppTypography.statNumber(c.accent, size: 52),
            children: [
              TextSpan(
                text: '/$total',
                style: AppTypography.statNumber(c.textMuted, size: 24),
              ),
            ],
          ),
        );
      },
    );
  }
}
