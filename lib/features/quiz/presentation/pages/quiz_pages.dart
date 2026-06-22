import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/quiz_models.dart';
import '../quiz_cubits.dart';

/// `/quizzes` — the student's available-quiz list, loaded live.
class StudentQuizListPage extends StatelessWidget {
  const StudentQuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizListCubit>(
      create: (_) => sl<QuizListCubit>()..loadAvailable(),
      child: const _QuizListView(),
    );
  }
}

class _QuizListView extends StatelessWidget {
  const _QuizListView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: PageHeader(
                      eyebrow: 'QUIZZES',
                      title: 'Take a',
                      emphasis: 'quiz.',
                      subtitle: 'Quizzes assigned by your teachers appear here.',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(RoutePaths.quizHistory),
                    icon: Icon(LucideIcons.history, size: 16, color: c.accent),
                    label: Text('History', style: AppTypography.bodyMedium(c.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              BlocBuilder<QuizListCubit, QuizListState>(
                builder: (context, state) {
                  if (state.status == Load.loading) {
                    return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (state.available.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: const EmptyState(
                        icon: LucideIcons.listChecks,
                        title: 'No quizzes yet',
                        hint: 'When a teacher assigns a quiz, you can start it here.',
                      ),
                    );
                  }
                  return Column(
                    children: [for (final q in state.available) _QuizCard(quiz: q)],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});
  final QuizSummary quiz;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final completed = quiz.status == 'completed';
    final inProgress = quiz.status == 'in_progress';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(quiz.title,
                    style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 17)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(quiz.status.replaceAll('_', ' ').toUpperCase(),
                    style: AppTypography.mono(c.accent, size: 9)),
              ),
            ],
          ),
          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(quiz.description, style: AppTypography.bodySmall(c.textMuted)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.fileQuestion, size: 14, color: c.textMuted),
              const SizedBox(width: 4),
              Text('${quiz.totalQuestions} questions',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(width: 16),
              Icon(LucideIcons.award, size: 14, color: c.textMuted),
              const SizedBox(width: 4),
              Text('${quiz.totalMarks} marks', style: AppTypography.bodySmall(c.textMuted)),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (completed) {
                    // Without an attemptId here, send to history.
                    context.go(RoutePaths.quizHistory);
                  } else {
                    context.go('/quiz/${quiz.id}/attempt/new');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: Text(completed
                    ? 'View result'
                    : inProgress
                        ? 'Resume'
                        : 'Start Quiz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `/quiz/:quizId/attempt/:attemptId` — the timed quiz-taking screen. When the
/// attemptId is "new", a fresh attempt is started for the quiz.
class QuizAttemptPage extends StatelessWidget {
  const QuizAttemptPage({super.key, required this.quizId, required this.attemptId});
  final String quizId;
  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizAttemptCubit>(
      create: (_) {
        final cubit = sl<QuizAttemptCubit>();
        if (attemptId == 'new' || attemptId.isEmpty) {
          cubit.start(quizId);
        } else {
          cubit.load(attemptId);
        }
        return cubit;
      },
      child: const _QuizAttemptView(),
    );
  }
}

class _QuizAttemptView extends StatelessWidget {
  const _QuizAttemptView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<QuizAttemptCubit, QuizAttemptState>(
      listenWhen: (p, n) => p.submittedAttemptId != n.submittedAttemptId,
      listener: (context, state) {
        final id = state.submittedAttemptId;
        if (id == null) return;
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
        if (state.status == Load.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == Load.error || state.attempt == null) {
          return Center(
              child: Text(state.error ?? 'Could not load quiz',
                  style: AppTypography.bodyMedium(c.danger)));
        }
        final answeredCount = state.answeredCount;
        final progress = state.total == 0 ? 0.0 : answeredCount / state.total;
        final deadline = state.attempt!.deadline;

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
                    icon: Icon(LucideIcons.arrowLeft, size: 18, color: c.textMuted),
                    tooltip: 'Leave',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.attempt!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                        Text('Q ${state.index + 1} / ${state.total}',
                            style: AppTypography.mono(c.textMuted, size: 11)),
                      ],
                    ),
                  ),
                  if (deadline != null) ...[
                    _CountdownTimer(deadline: deadline, onExpire: () {
                      if (!state.submitting && state.submittedAttemptId == null) {
                        cubit.submit();
                      }
                    }),
                    const SizedBox(width: 10),
                  ],
                  FilledButton.icon(
                    onPressed: state.submitting ? null : () => _confirmSubmit(context, state),
                    icon: const Icon(LucideIcons.send, size: 14),
                    label: const Text('Submit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.bgCard,
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        children: [
                          Text('Question ${state.index + 1} of ${state.total}',
                              style: AppTypography.mono(c.textPrimary, size: 12)),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => _showMobileNavigator(context, cubit, state),
                            style: FilledButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      },
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
            style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) context.go(RoutePaths.quizzes);
  }

  Future<void> _confirmSubmit(BuildContext context, QuizAttemptState state) async {
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
              decoration: BoxDecoration(color: c.warningBg, borderRadius: BorderRadius.circular(4)),
              child: Icon(LucideIcons.triangleAlert, size: 18, color: c.warning),
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
              child: Text('Review Answers', style: AppTypography.button(c.textMuted))),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dctx, true),
            icon: const Icon(LucideIcons.send, size: 14),
            label: const Text('Submit Quiz'),
            style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
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
      BuildContext context, QuizAttemptCubit cubit, QuizAttemptState state) {
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
  final QuizAttemptState state;
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFlagged ? c.warningBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.flag,
                                  size: 14, color: isFlagged ? c.warning : c.textMuted),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.bgPrimary,
                    border: Border(top: BorderSide(color: c.border)),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: state.index < state.total - 1 ? cubit.next : null,
                        icon: const Icon(LucideIcons.chevronRight, size: 16),
                        label: const Text('Next'),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                    style: AppTypography.mono(selected ? Colors.white : c.textMuted, size: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: AppTypography.bodyMedium(selected ? c.textPrimary : c.textMuted)),
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
  final QuizAttemptState state;
  final QuizAttemptCubit cubit;
  final VoidCallback? onTapQuestion;
  final bool showCounters;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final questions = state.attempt?.questions ?? const [];
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
                      border: Border.all(color: c.border),
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
                  if (isFlagged)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle),
                      ),
                    ),
                ],
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
                Text('ANSWERED', style: AppTypography.mono(c.textMuted, size: 10)),
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
class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({required this.deadline, required this.onExpire});
  final DateTime deadline;
  final VoidCallback onExpire;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _ticker;
  bool _flash = false;
  bool _expired = false;

  int get _remaining =>
      widget.deadline.difference(DateTime.now()).inSeconds.clamp(0, 1 << 31);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final r = _remaining;
      if (r <= 0 && !_expired) {
        _expired = true;
        widget.onExpire();
      }
      setState(() => _flash = !_flash);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

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
      bg = c.warning.withValues(alpha: _flash ? 0.2 : 0.1);
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

/// `/quiz/result/:attemptId` — graded result + answer review.
class QuizResultPage extends StatelessWidget {
  const QuizResultPage({super.key, required this.attemptId});
  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizResultCubit>(
      create: (_) => sl<QuizResultCubit>()..load(attemptId),
      child: const _QuizResultView(),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  const _QuizResultView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<QuizResultCubit, QuizResultState>(
      builder: (context, state) {
        if (state.status == Load.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = state.result;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Icon(LucideIcons.trophy, size: 40, color: c.accentSecondary),
                  const SizedBox(height: 12),
                  Text('Quiz Complete!',
                      style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 28)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ResultStat(value: r == null ? '—' : '${r.score}/${r.totalMarks}', label: 'SCORE'),
                      const SizedBox(width: 12),
                      _ResultStat(value: r == null ? '—' : '${r.percentage.round()}%', label: 'ACCURACY'),
                      const SizedBox(width: 12),
                      _ResultStat(value: r?.passStatus.toUpperCase() ?? '—', label: 'STATUS'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (r != null)
                    for (var i = 0; i < r.questions.length; i++)
                      _ReviewTile(index: i, q: r.questions[i]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go(RoutePaths.quizzes),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Back to Quizzes', style: AppTypography.button(c.textPrimary)),
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

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.index, required this.q});
  final int index;
  final QuizReviewQuestion q;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(q.isCorrect ? LucideIcons.circleCheck : LucideIcons.circleX,
                  size: 16, color: q.isCorrect ? c.success : c.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Q${index + 1}. ${q.text}',
                    style: AppTypography.bodyMedium(c.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Your answer: ${q.userAnswer.isEmpty ? "—" : q.userAnswer}',
              style: AppTypography.bodySmall(q.isCorrect ? c.success : c.danger)),
          if (!q.isCorrect)
            Text('Correct: ${q.correctAnswer}', style: AppTypography.bodySmall(c.textMuted)),
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(q.explanation, style: AppTypography.bodySmall(c.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(),
        child: Column(
          children: [
            Text(value, style: AppTypography.statNumber(c.accent, size: 22)),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
          ],
        ),
      ),
    );
  }
}

/// `/quiz/history` — past attempts, loaded live.
class QuizHistoryPage extends StatelessWidget {
  const QuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizListCubit>(
      create: (_) => sl<QuizListCubit>()..loadHistory(),
      child: const _QuizHistoryView(),
    );
  }
}

class _QuizHistoryView extends StatefulWidget {
  const _QuizHistoryView();
  @override
  State<_QuizHistoryView> createState() => _QuizHistoryViewState();
}

class _QuizHistoryViewState extends State<_QuizHistoryView> {
  String _query = '';
  int _page = 1;
  static const _perPage = 10;

  String _fmtDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $hh:$mm';
  }

  String _fmtTime(int s) => '${s ~/ 60}m ${s % 60}s';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go(RoutePaths.quizzes),
                icon: Icon(LucideIcons.arrowLeft, size: 16, color: c.textMuted),
                label: Text('Back to Quizzes', style: AppTypography.bodyMedium(c.textMuted)),
              ),
              const SizedBox(height: 8),
              const PageHeader(eyebrow: 'QUIZZES', title: 'Attempt', emphasis: 'history.'),
              const SizedBox(height: 20),
              // Search
              TextField(
                onChanged: (v) => setState(() {
                  _query = v;
                  _page = 1;
                }),
                decoration: InputDecoration(
                  hintText: 'Search by quiz title...',
                  prefixIcon: Icon(LucideIcons.search, size: 18, color: c.textMuted),
                  filled: true,
                  fillColor: c.bgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              BlocBuilder<QuizListCubit, QuizListState>(
                builder: (context, state) {
                  if (state.status == Load.loading) {
                    return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final filtered = state.history
                      .where((h) => h.quizTitle.toLowerCase().contains(_query.toLowerCase()))
                      .toList();
                  if (filtered.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: EmptyState(
                        icon: LucideIcons.history,
                        title: 'No quiz history',
                        hint: _query.isNotEmpty
                            ? 'No attempts match your search'
                            : "You haven't completed any quizzes yet",
                      ),
                    );
                  }
                  final pages = (filtered.length / _perPage).ceil();
                  final page = _page.clamp(1, pages);
                  final slice = filtered.skip((page - 1) * _perPage).take(_perPage).toList();
                  return Column(
                    children: [
                      for (final h in slice) _HistoryCard(
                        item: h,
                        date: _fmtDate(h.submittedAt),
                        time: _fmtTime(h.timeSpent),
                      ),
                      if (pages > 1) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: page > 1 ? () => setState(() => _page = page - 1) : null,
                              child: const Text('Previous'),
                            ),
                            const SizedBox(width: 12),
                            Text('Page $page of $pages',
                                style: AppTypography.bodyMedium(c.textMuted)),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: page < pages ? () => setState(() => _page = page + 1) : null,
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.date, required this.time});
  final QuizHistoryItem item;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final passed = item.isPassed;
    final statusColor = passed ? c.success : c.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/quiz/result/${item.attemptId}'),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: context.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(passed ? LucideIcons.trophy : LucideIcons.circleX,
                    size: 22, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.quizTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge(c.textPrimary)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.calendar, size: 13, color: c.textMuted),
                          const SizedBox(width: 4),
                          Text(date, style: AppTypography.bodySmall(c.textMuted)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.clock, size: 13, color: c.textMuted),
                          const SizedBox(width: 4),
                          Text(time, style: AppTypography.bodySmall(c.textMuted)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.percentage.round()}%',
                      style: AppTypography.statNumber(statusColor, size: 22)),
                  Text('${item.score}/${item.totalMarks}',
                      style: AppTypography.mono(c.textMuted, size: 11)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
