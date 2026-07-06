part of '../quiz_pages.dart';

class _QuizAttemptView extends StatelessWidget {
  const _QuizAttemptView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<QuizAttemptCubit, QuizSessionState>(
      listenWhen: (p, n) =>
          n is QuizSubmitted && (p is! QuizSubmitted || p.attemptId != n.attemptId),
      listener: (context, state) {
        if (state is! QuizSubmitted) return;
        final id = state.attemptId;
        // Celebration overlay, then navigate to the result (mirrors the frontend).
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (_) => const _CelebrationOverlay(),
        );
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (!context.mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
          context.go('/quiz/result/$id');
        });
      },
      builder: (context, state) {
        final cubit = context.read<QuizAttemptCubit>();
        return switch (state) {
          QuizSessionLoading() => _loadingView(c),
          QuizSessionFailed(:final message) => _errorView(c, message),
          QuizSessionLoaded() => _sessionView(context, c, cubit, state),
        };
      },
    );
  }

  Widget _loadingView(AskAideColors c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: c.accent),
          ),
          const SizedBox(height: 16),
          Text('Loading quiz...', style: AppTypography.mono(c.textMuted, size: 13)),
        ],
      ),
    );
  }

  Widget _errorView(AskAideColors c, String message) {
    return Center(
        child: Text(message, style: AppTypography.bodyMedium(c.danger)));
  }

  Widget _sessionView(BuildContext context, AskAideColors c,
      QuizAttemptCubit cubit, QuizSessionLoaded state) {
        final answeredCount = state.answeredCount;
        final progress = state.total == 0 ? 0.0 : answeredCount / state.total;
        final deadline = state.attempt.deadline;

        return Column(
          children: [
            // Header: back, title + Q x/y, countdown, submit.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: c.bgCard,
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _confirmLeave(context),
                    icon: Icon(LucideIcons.arrowLeft,
                        size: 18, color: c.textMuted),
                    tooltip: 'Leave',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.attempt.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h4(c.textPrimary)
                                .copyWith(fontSize: 16)),
                        Text('Q ${state.index + 1} / ${state.total}',
                            style: AppTypography.mono(c.textMuted, size: 11)),
                      ],
                    ),
                  ),
                  if (deadline != null) ...[
                    _CountdownTimer(
                        deadline: deadline,
                        onExpire: () {
                          if (state is QuizInProgress) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Time is up! Submitting your quiz...')),
                            );
                            cubit.submit();
                          }
                        }),
                    const SizedBox(width: 10),
                  ],
                  FilledButton.icon(
                    onPressed: state is QuizInProgress
                        ? () => _confirmSubmit(context, state)
                        : null,
                    icon: const Icon(LucideIcons.send, size: 14),
                    label: const Text('Submit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar (by answered count, matching the frontend).
            SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                  value: progress, backgroundColor: c.border, color: c.accent),
            ),
            // Body: question panel + (desktop) navigator sidebar.
            Expanded(
              child: LayoutBuilder(builder: (context, cons) {
                final wide = cons.maxWidth >= 900;
                final panel = _QuestionPanel(state: state, cubit: cubit);
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: panel),
                      Container(
                        width: 240,
                        decoration: BoxDecoration(
                          color: c.bgCard,
                          border: Border(left: BorderSide(color: c.border)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _QuestionNavigator(state: state, cubit: cubit),
                        ),
                      ),
                    ],
                  );
                }
                // Mobile: panel + bottom bar with "Show all".
                return Column(
                  children: [
                    Expanded(child: panel),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.bgCard,
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        children: [
                          Text('Question ${state.index + 1} of ${state.total}',
                              style:
                                  AppTypography.mono(c.textPrimary, size: 12)),
                          const Spacer(),
                          FilledButton(
                            onPressed: () =>
                                _showMobileNavigator(context, cubit, state),
                            style: FilledButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Text('Show all'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final c = context.colors;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: c.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Leave quiz?', style: AppTypography.h4(c.textPrimary)),
        content: Text('Your progress is saved. You can resume later.',
            style: AppTypography.bodyMedium(c.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text('Cancel', style: AppTypography.button(c.textMuted))),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: Colors.white),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) context.go(RoutePaths.quizzes);
  }

  Future<void> _confirmSubmit(
      BuildContext context, QuizSessionLoaded state) async {
    final c = context.colors;
    final cubit = context.read<QuizAttemptCubit>();
    final unanswered = state.total - state.answeredCount;
    final go = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: c.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: c.warningBg, borderRadius: BorderRadius.circular(4)),
              child:
                  Icon(LucideIcons.triangleAlert, size: 18, color: c.warning),
            ),
            const SizedBox(width: 12),
            Text('Submit Quiz?', style: AppTypography.h4(c.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You are about to submit your quiz. Here's your summary:",
                style: AppTypography.bodyMedium(c.textMuted)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.bgPrimary,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  _summaryRow(context, 'Answered', state.answeredCount),
                  const SizedBox(height: 8),
                  _summaryRow(context, 'Unanswered', unanswered),
                  const SizedBox(height: 8),
                  _summaryRow(context, 'Flagged', state.flaggedCount),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text('Review Answers',
                  style: AppTypography.button(c.textMuted))),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dctx, true),
            icon: const Icon(LucideIcons.send, size: 14),
            label: const Text('Submit Quiz'),
            style: FilledButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
    if (go == true) cubit.submit();
  }

  Widget _summaryRow(BuildContext context, String label, int value) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(c.textMuted)),
        Text('$value', style: AppTypography.mono(c.textPrimary, size: 13)),
      ],
    );
  }

  void _showMobileNavigator(
      BuildContext context, QuizAttemptCubit cubit, QuizSessionLoaded state) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (sctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: _QuestionNavigator(
          state: state,
          cubit: cubit,
          onTapQuestion: () => Navigator.pop(sctx),
          showCounters: false,
        ),
      ),
    );
  }
}

/// The central question card: header (number + marks + flag), text, options, nav.
class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({required this.state, required this.cubit});
  final QuizSessionLoaded state;
  final QuizAttemptCubit cubit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = state.current;
    if (q == null) return const SizedBox();
    final isFlagged = state.flagged.contains(q.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.accentLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${state.index + 1}',
                            style: AppTypography.mono(c.accent, size: 13)),
                      ),
                      const SizedBox(width: 12),
                      Text('${q.marks} mark${q.marks > 1 ? 's' : ''}',
                          style: AppTypography.mono(c.textMuted, size: 11)),
                      const Spacer(),
                      InkWell(
                        onTap: cubit.toggleFlag,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFlagged ? c.warningBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.flag,
                                  size: 14,
                                  color: isFlagged ? c.warning : c.textMuted),
                              const SizedBox(width: 6),
                              Text(isFlagged ? 'Marked' : 'Mark for review',
                                  style: AppTypography.bodySmall(
                                      isFlagged ? c.warning : c.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Question text + options
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.text,
                          style: AppTypography.h4(c.textPrimary)
                              .copyWith(fontSize: 18, height: 1.6)),
                      const SizedBox(height: 20),
                      for (var i = 0; i < q.options.length; i++)
                        _AttemptOption(
                          letter: String.fromCharCode(65 + i),
                          text: q.options[i],
                          selected: state.answers[q.id] == q.options[i],
                          onTap: () => cubit.select(q.options[i]),
                        ),
                    ],
                  ),
                ),
                // Footer nav
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.bgPrimary,
                    border: Border(top: BorderSide(color: c.border)),
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.index > 0 ? cubit.prev : null,
                        icon: const Icon(LucideIcons.chevronLeft, size: 16),
                        label: const Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed:
                            state.index < state.total - 1 ? cubit.next : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Next'),
                            SizedBox(width: 6),
                            Icon(LucideIcons.chevronRight, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single answer option (A/B/C/D) with selected styling + check icon.
class _AttemptOption extends StatelessWidget {
  const _AttemptOption({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? c.accentLight : c.bgCard,
            border: Border.all(color: selected ? c.accent : c.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? c.accent : c.bgPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(letter,
                    style: AppTypography.mono(
                        selected ? Colors.white : c.textMuted,
                        size: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: AppTypography.bodyMedium(
                        selected ? c.textPrimary : c.textMuted)),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.circleCheck, size: 16, color: c.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The question navigator grid (1·2·3…) with legend + answered/flagged counters.
class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({
    required this.state,
    required this.cubit,
    this.onTapQuestion,
    this.showCounters = true,
  });
  final QuizSessionLoaded state;
  final QuizAttemptCubit cubit;
  final VoidCallback? onTapQuestion;
  final bool showCounters;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final questions = state.attempt.questions;
    final unanswered = state.total - state.answeredCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('QUESTIONS', style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, idx) {
            final qid = questions[idx].id;
            final isActive = idx == state.index;
            final isAnswered = state.answers.containsKey(qid);
            final isFlagged = state.flagged.contains(qid);
            return InkWell(
              onTap: () {
                cubit.goTo(idx);
                onTapQuestion?.call();
              },
              borderRadius: BorderRadius.circular(4),
              child: Opacity(
                opacity: (!isAnswered && !isActive) ? 0.6 : 1.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? c.accent
                            : isAnswered
                                ? c.accentLight
                                : c.bgPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${idx + 1}',
                          style: AppTypography.mono(
                              isActive
                                  ? Colors.white
                                  : isAnswered
                                      ? c.accent
                                      : c.textMuted,
                              size: 12)),
                    ),
                    if (!isAnswered && !isActive)
                      Positioned(
                        bottom: 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: c.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    if (isFlagged)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: c.warning, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _legendRow(context, c.accentLight, 'Answered'),
        const SizedBox(height: 6),
        _legendRow(context, c.bgPrimary, 'Not answered'),
        const SizedBox(height: 6),
        _legendRow(context, c.accent, 'Current'),
        if (state.flaggedCount > 0) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.warningBg,
              border: Border.all(color: c.warning.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.flag, size: 12, color: c.warning),
                const SizedBox(width: 6),
                Text('${state.flaggedCount} marked for review',
                    style: AppTypography.mono(c.warning, size: 11)),
              ],
            ),
          ),
        ],
        if (showCounters) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.bgPrimary,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text('${state.answeredCount}/${state.total}',
                    style: AppTypography.statNumber(c.textPrimary, size: 22)),
                Text('ANSWERED',
                    style: AppTypography.mono(c.textMuted, size: 10)),
                if (unanswered > 0) ...[
                  const SizedBox(height: 4),
                  Text('$unanswered unanswered',
                      style: AppTypography.mono(c.danger, size: 10)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _legendRow(BuildContext context, Color color, String label) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.mono(c.textMuted, size: 11)),
      ],
    );
  }
}

/// A count-DOWN timer (MM:SS) that flashes amber under 5 min, red under 1 min,
/// and fires [onExpire] once when it reaches zero.
class _CountdownTimer extends StatelessWidget {
  const _CountdownTimer({required this.deadline, required this.onExpire});
  final DateTime deadline;
  final VoidCallback onExpire;

  int get _remaining =>
      deadline.difference(DateTime.now()).inSeconds.clamp(0, 1 << 31);

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CountdownCubit>(
      create: (_) => sl<CountdownCubit>(param1: deadline, param2: onExpire),
      child: BlocBuilder<CountdownCubit, bool>(
        builder: (context, flash) {
          final c = context.colors;
          final r = _remaining;
          Color fg;
          Color bg;
          Color border;
          if (r <= 60) {
            fg = c.danger;
            bg = c.danger.withValues(alpha: 0.1);
            border = c.danger;
          } else if (r <= 300) {
            fg = c.warning;
            bg = c.warning.withValues(alpha: flash ? 0.2 : 0.1);
            border = c.warning;
          } else {
            fg = c.textMuted;
            bg = c.bgCard;
            border = c.border;
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.clock, size: 13, color: fg),
                const SizedBox(width: 6),
                Text(_fmt(r), style: AppTypography.mono(fg, size: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The "Quiz Complete!" celebration shown briefly before the result page.
class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Quiz Complete!',
                style: AppTypography.h2(Colors.white).copyWith(fontSize: 30)),
            const SizedBox(height: 8),
            Text('Loading your results...',
                style: AppTypography.bodyLarge(Colors.white70)),
          ],
        ),
      ),
    );
  }
}
