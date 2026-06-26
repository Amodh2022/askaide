import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/user_answer.dart';
import '../bloc/session_bloc.dart';

/// Review of a past session. Mirrors the React `UserAnswers` view: a summary
/// header (accuracy, correct/total) followed by a chat-style transcript of each
/// answered question — the question (with its options and time spent), the
/// user's answer, and a correct/incorrect feedback bubble carrying the correct
/// answer and explanation.
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
        final isLoading = state.reviewStatus == LoadStatus.loading;
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
                  const SizedBox(height: 4),
                  Text('${session.answeredCount} questions answered',
                      style: AppTypography.bodySmall(c.textMuted)),
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
                  if (isLoading)
                    _ReviewShimmer()
                  else
                    ...session.answers.asMap().entries.map(
                          (e) => _AnswerThread(index: e.key, answer: e.value),
                        ),
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

/// Shimmer placeholder for the questions list while answers are being fetched.
class _ReviewShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => _ShimmerThread(c: c)),
      ),
    );
  }
}

class _ShimmerThread extends StatelessWidget {
  const _ShimmerThread({required this.c});
  final AskAideColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot question bubble (left-aligned)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: c.bgRaised, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.bgRaised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 14, width: double.infinity),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 260),
                      SizedBox(height: 6),
                      SkeletonBox(height: 12, width: 220),
                      SizedBox(height: 6),
                      SkeletonBox(height: 12, width: 240),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // User answer bubble (right-aligned)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.bgRaised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SkeletonBox(height: 14, width: 140),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: c.bgRaised, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Feedback bubble (left-aligned)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: c.bgRaised, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.bgRaised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 14, width: 180),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 300),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One question's transcript: the bot's question, the user's answer and the
/// feedback, rendered as a chat thread.
class _AnswerThread extends StatelessWidget {
  const _AnswerThread({required this.index, required this.answer});

  final int index;
  final UserAnswer answer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ok = answer.isCorrect;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot's question.
          _Bubble(
            alignEnd: false,
            avatar: _avatar(c.accentLight, LucideIcons.bot, c.accent),
            bubbleColor: c.accent.withValues(alpha: 0.10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer.questionText?.isNotEmpty == true
                      ? answer.questionText!
                      : 'Question ${index + 1}',
                  style: AppTypography.bodyMedium(c.textPrimary),
                ),
                if (answer.options.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...answer.options.map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $o',
                          style: AppTypography.bodySmall(c.textMuted)),
                    ),
                  ),
                ],
                if (answer.timeSpentSeconds != null) ...[
                  const SizedBox(height: 8),
                  Text('⏱ ${answer.timeSpentSeconds}s',
                      style: AppTypography.bodySmall(c.textMuted)
                          .copyWith(fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // User's answer.
          _Bubble(
            alignEnd: true,
            avatar: _avatar(c.bgSecondary, LucideIcons.user, c.textMuted),
            bubbleColor: (ok ? c.success : c.danger).withValues(alpha: 0.15),
            child: Text(answer.answer, style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          const SizedBox(height: 8),
          // Feedback.
          _Bubble(
            alignEnd: false,
            avatar: _avatar((ok ? c.success : c.danger).withValues(alpha: 0.2),
                LucideIcons.bot, ok ? c.success : c.danger),
            bubbleColor: (ok ? c.success : c.danger).withValues(alpha: 0.10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok
                      ? '✓ Correct!'
                      : '✗ Incorrect. The answer is: ${answer.correctAnswer ?? '—'}',
                  style: AppTypography.bodyMedium(ok ? c.success : c.danger)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (answer.explanation?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(answer.explanation!,
                      style: AppTypography.bodySmall(c.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Color bg, IconData icon, Color fg) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: fg),
      );
}

/// A single chat row: an avatar and a coloured bubble, left- or right-aligned.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.alignEnd,
    required this.avatar,
    required this.bubbleColor,
    required this.child,
  });

  final bool alignEnd;
  final Widget avatar;
  final Color bubbleColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bubble = Flexible(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
    );
    final children = alignEnd
        ? [bubble, const SizedBox(width: 8), avatar]
        : [avatar, const SizedBox(width: 8), bubble];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: children,
    );
  }
}
