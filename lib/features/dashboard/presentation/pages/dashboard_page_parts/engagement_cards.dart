part of '../dashboard_page.dart';

class _ContinueBanner extends StatelessWidget {
  const _ContinueBanner({required this.session});
  final ContinueSessionInfo session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContinueBannerCubit>(
      create: (_) => sl<ContinueBannerCubit>(),
      child: BlocBuilder<ContinueBannerCubit, bool>(
        builder: (context, dismissed) =>
            dismissed ? const SizedBox.shrink() : _buildBanner(context),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(6)),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(LucideIcons.bookOpen, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue your session',
                        style: AppTypography.h4(Colors.white).copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${session.chapter} · ${session.answeredCount} answered · ${_timeAgo(session.startedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(Colors.white70, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.go(RoutePaths.study),
                icon: const Icon(LucideIcons.play, size: 13),
                label: const Text('Resume'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: () => context.read<ContinueBannerCubit>().dismiss(),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime? d) {
    if (d == null) return 'recently';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }
}

/// Today's daily challenge, focused on the user's weakest topic.
class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});
  final DailyChallengeInfo challenge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = challenge.completed;
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: done
                  ? null
                  : LinearGradient(colors: [c.accent, c.accentSecondary]),
              color: done ? c.accent : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GradientIcon(
                      done ? LucideIcons.circleCheckBig : LucideIcons.zap,
                      secondary: !done,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Challenge',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                          Text(done ? 'Completed! 🎉' : 'Focus on your weak spots',
                              style: AppTypography.bodySmall(c.textSecondary)),
                        ],
                      ),
                    ),
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.successBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('${challenge.score}/${challenge.totalQuestions}',
                            style: AppTypography.mono(c.success, size: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.topicName,
                          style: AppTypography.labelLarge(c.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        '${challenge.subjectName} • ${challenge.totalQuestions} questions • ${challenge.difficulty}',
                        style: AppTypography.bodySmall(c.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!done) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go(RoutePaths.study),
                      icon: const Icon(LucideIcons.zap, size: 16),
                      label: const Text('Start Challenge  →'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              'I just scored ${challenge.score}/${challenge.totalQuestions} '
                              "on today's Daily Challenge in ${challenge.subjectName}! 🎯 "
                              'Try AskAide and beat my score!',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Result copied!')),
                        );
                      },
                      icon: const Icon(LucideIcons.share2, size: 15),
                      label: const Text('Share result'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.accent,
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (challenge.completedAt != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clock, size: 12, color: c.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Completed at ${TimeOfDay.fromDateTime(challenge.completedAt!.toLocal()).format(context)}',
                            style: AppTypography.bodySmall(c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
