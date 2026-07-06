part of '../quiz_pages.dart';

class _QuizResultView extends StatelessWidget {
  const _QuizResultView();

  String _formatTime(int seconds) => '${seconds ~/ 60}m ${seconds % 60}s';

  String _improvementLabel(double pct, double prev) {
    final diff = (pct - prev).round();
    if (diff > 0) return "That's $diff% higher than your last quiz — nice improvement!";
    if (diff < 0) return "That's ${diff.abs()}% lower than your last quiz. Keep practicing!";
    return 'Same score as your last quiz — keep it up!';
  }

  Widget _scoreComparisonBadge(
      BuildContext context, double pct, double prev) {
    final diff = (pct - prev).round();
    final sign = diff > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppRadii.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('VS LAST QUIZ',
              style: AppTypography.mono(Colors.white70, size: 10)),
          const SizedBox(height: 4),
          Text('$sign$diff%',
              style: AppTypography.statNumber(Colors.white, size: 22)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<QuizResultCubit, QuizResultState>(
      builder: (context, state) {
        if (state.status == Load.loading) {
          return const SkeletonListLoader();
        }
        final r = state.result;
        if (r == null) {
          return Center(
              child: Text('Could not load results',
                  style: AppTypography.bodyMedium(c.danger)));
        }
        final passed = r.passed;
        final scoreColor = passed ? c.accent : c.danger;
        final incorrect =
            (r.questions.length - r.correctCount).clamp(0, r.questions.length);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + header
                  TextButton.icon(
                    onPressed: () => context.go(RoutePaths.quizzes),
                    icon: Icon(LucideIcons.arrowLeft,
                        size: 16, color: c.textMuted),
                    label: Text('Back to Quizzes',
                        style: AppTypography.bodyMedium(c.textMuted)),
                  ),
                  const SizedBox(height: 4),
                  Text('QUIZ RESULTS',
                      style: AppTypography.sectionLabel(c.textMuted)),
                  const SizedBox(height: 6),
                  Text(r.quizTitle,
                      style: AppTypography.h2(c.textPrimary)
                          .copyWith(fontSize: 26)),
                  const SizedBox(height: 20),

                  // Score card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: AppRadii.cardR),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                      passed
                                          ? LucideIcons.trophy
                                          : LucideIcons.circleAlert,
                                      size: 18,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      passed
                                          ? 'Congratulations! You Passed!'
                                          : 'Keep Trying!',
                                      style: AppTypography.bodyMedium(
                                          Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('${r.percentage.round()}%',
                                  style: AppTypography.statNumber(Colors.white,
                                      size: 52)),
                              const SizedBox(height: 4),
                              Text('${r.score} / ${r.totalMarks} marks',
                                  style: AppTypography.mono(Colors.white70,
                                      size: 13)),
                              if (r.previousBestPercentage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _improvementLabel(
                                      r.percentage, r.previousBestPercentage!),
                                  style: AppTypography.bodySmall(Colors.white70),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (r.previousBestPercentage != null)
                              _scoreComparisonBadge(
                                  context,
                                  r.percentage,
                                  r.previousBestPercentage!),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: AppRadii.cardR,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('PASSING SCORE',
                                      style: AppTypography.mono(Colors.white70,
                                          size: 10)),
                                  const SizedBox(height: 4),
                                  Text('${r.passingPercentage.round()}%',
                                      style: AppTypography.statNumber(
                                          Colors.white, size: 22)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stat grid
                  LayoutBuilder(builder: (context, cons) {
                    final cols = cons.maxWidth >= 560 ? 4 : 2;
                    const gap = 12.0;
                    final w = (cons.maxWidth - gap * (cols - 1)) / cols;
                    final stats = [
                      (
                        icon: LucideIcons.circleCheck,
                        color: c.accent,
                        label: 'CORRECT',
                        value: '${r.correctCount}'
                      ),
                      (
                        icon: LucideIcons.circleX,
                        color: c.danger,
                        label: 'INCORRECT',
                        value: '$incorrect'
                      ),
                      (
                        icon: LucideIcons.fileText,
                        color: c.textMuted,
                        label: 'QUESTIONS',
                        value: '${r.questions.length}'
                      ),
                      (
                        icon: LucideIcons.clock,
                        color: c.textMuted,
                        label: 'TIME SPENT',
                        value: _formatTime(r.timeSpent)
                      ),
                    ];
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final s in stats)
                          SizedBox(
                            width: w,
                            child: _ResultStat(
                                icon: s.icon,
                                color: s.color,
                                value: s.value,
                                label: s.label),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),

                  // Question review
                  if (r.showAnswers && r.questions.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              border:
                                  Border(bottom: BorderSide(color: c.border)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.bookOpen,
                                    size: 18, color: c.accent),
                                const SizedBox(width: 8),
                                Text('Question Review',
                                    style: AppTypography.h4(c.textPrimary)
                                        .copyWith(fontSize: 16)),
                              ],
                            ),
                          ),
                          for (var i = 0; i < r.questions.length; i++)
                            _ReviewTile(
                              index: i,
                              q: r.questions[i],
                              isLast: i == r.questions.length - 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go(RoutePaths.quizzes),
                          icon: const Icon(LucideIcons.bookOpen, size: 16),
                          label: const Text('More Quizzes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.textPrimary,
                            side: BorderSide(color: c.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppRadii.cardR),
                          ),
                        ),
                        if (r.canRetry && r.quizId.isNotEmpty)
                          FilledButton.icon(
                            onPressed: () =>
                                context.go('/quiz/${r.quizId}/attempt/new'),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Try Again'),
                            style: FilledButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadii.cardR),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A collapsible reviewed-question row in the result screen.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile(
      {required this.index, required this.q, this.isLast = false});
  final int index;
  final QuizReviewQuestion q;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReviewTileCubit>(
      create: (_) => sl<ReviewTileCubit>(),
      child: Builder(builder: _buildTile),
    );
  }

  Widget _buildTile(BuildContext context) {
    final c = context.colors;
    final correct = q.isCorrect;
    final expanded = context.watch<ReviewTileCubit>().state;
    return Container(
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.read<ReviewTileCubit>().toggle(),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: correct
                          ? c.accentLight
                          : c.danger.withValues(alpha: 0.1),
                      borderRadius: AppRadii.cardR,
                    ),
                    child: Text('${index + 1}',
                        style: AppTypography.mono(correct ? c.accent : c.danger,
                            size: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.text,
                            style: AppTypography.bodyMedium(c.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                                correct
                                    ? LucideIcons.circleCheck
                                    : LucideIcons.circleX,
                                size: 13,
                                color: correct ? c.accent : c.danger),
                            const SizedBox(width: 4),
                            Text(correct ? 'Correct' : 'Incorrect',
                                style: AppTypography.bodySmall(
                                    correct ? c.accent : c.danger)),
                            const SizedBox(width: 10),
                            Text('${q.marksObtained}/${q.marks} marks',
                                style:
                                    AppTypography.mono(c.textMuted, size: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                      expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: c.textMuted),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _answerBox(context,
                      label: 'YOUR ANSWER',
                      text:
                          q.userAnswer.isEmpty ? 'Not answered' : q.userAnswer,
                      fg: correct ? c.accent : c.danger,
                      bg: c.bgPrimary,
                      border: c.border),
                  if (!correct && q.correctAnswer.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _answerBox(context,
                        label: 'CORRECT ANSWER',
                        text: q.correctAnswer,
                        fg: c.accent,
                        bg: c.accentLight,
                        border: c.accent),
                  ],
                  if (q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _answerBox(context,
                        label: 'EXPLANATION',
                        text: q.explanation,
                        fg: c.textPrimary,
                        labelColor: c.textMuted,
                        bg: c.bgPrimary,
                        border: c.border),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _answerBox(BuildContext context,
      {required String label,
      required String text,
      required Color fg,
      required Color bg,
      required Color border,
      Color? labelColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: AppRadii.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.mono(labelColor ?? fg, size: 10)),
          const SizedBox(height: 4),
          Text(text,
              style: AppTypography.bodySmall(fg)
                  .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.statNumber(c.textPrimary, size: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
        ],
      ),
    );
  }
}
