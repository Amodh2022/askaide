import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/session_bloc.dart';

/// Review of a past session: a summary header (accuracy, correct/total) and a
/// list of recorded answers with correct/incorrect markers. Mirrors UserAnswers.
class UserAnswersPanel extends StatelessWidget {
  const UserAnswersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final session = state.reviewSession;
        if (session == null) {
          return Center(
              child: Text('Select a session to review.',
                  style: AppTypography.bodyMedium(c.textMuted)));
        }
        final pct = (session.accuracy * 100).round();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context
                            .read<SessionBloc>()
                            .add(const BackToConfigRequested()),
                        icon: Icon(LucideIcons.arrowLeft, size: 16, color: c.textMuted),
                        label: Text('Back', style: AppTypography.bodySmall(c.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('— SESSION REVIEW', style: AppTypography.sectionLabel(c.accent)),
                  const SizedBox(height: 8),
                  Text(session.title, style: AppTypography.h3(c.textPrimary)),
                  const SizedBox(height: 16),
                  // Summary cards
                  Row(
                    children: [
                      _stat(context, '$pct%', 'ACCURACY'),
                      const SizedBox(width: 12),
                      _stat(context, '${session.correctCount}/${session.answeredCount}', 'CORRECT'),
                      const SizedBox(width: 12),
                      _stat(context, '${session.answeredCount}', 'ANSWERED'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...session.answers.asMap().entries.map((e) {
                    final a = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: context.cardDecoration(),
                      child: Row(
                        children: [
                          Icon(a.isCorrect ? LucideIcons.circleCheck : LucideIcons.circleX,
                              size: 18, color: a.isCorrect ? c.success : c.danger),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Question ${e.key + 1}',
                                    style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('Your answer: ${a.answer}',
                                    style: AppTypography.bodyMedium(c.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.statNumber(c.accent, size: 28)),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
          ],
        ),
      ),
    );
  }
}
