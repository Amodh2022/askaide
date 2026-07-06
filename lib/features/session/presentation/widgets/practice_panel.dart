import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/study_enums.dart';
import '../bloc/session_bloc.dart';
import '../cubit/feedback_form_cubit.dart';
import '../cubit/generating_message_cubit.dart';
import '../cubit/practice_ui_cubit.dart';
import '../cubit/typewriter_cubit.dart';
import 'nps_survey_dialog.dart';
import 'question_answer_widget_factory.dart';
import 'session_result_modal.dart';

/// The in-session practice view: a progress header, the AI question bubble with
/// MCQ options (or a fill-in-the-blank input), instant correct/wrong feedback,
/// and Next / End controls. Mirrors the frontend QuestionPractice + CurrentQuestion.
class PracticePanel extends StatelessWidget {
  const PracticePanel({super.key});

  Future<void> _runEndOfSessionFlow(BuildContext context, PracticeUiCubit uiCubit) async {
    // Capture dependencies up front so we never touch a context across an await.
    final bloc = context.read<SessionBloc>();
    final userId = context.read<ProfileCubit>().state.user?.id ?? '';
    final summary = bloc.state.resultSummary;
    if (summary == null) return;

    // 1) Result modal summarising the session.
    await showSessionResultModal(context, summary);
    if (!context.mounted) return;

    // 2) Post-session NPS survey — only when the server says the user is due
    //    one (mirrors React's checkNpsEligibility gate) and not already shown.
    if (bloc.state.npsEligible && !bloc.state.npsHandled) {
      final result = await showNpsSurvey(context);
      if (!context.mounted) return;
      if (result == null) {
        bloc.add(const NpsDismissed());
      } else {
        bloc.add(NpsSubmitted(
          userId: userId,
          score: result.score,
          comment: result.comment,
        ));
      }
    }

    // 3) Tear down and return to the config panel.
    bloc.add(const ResultModalDismissed());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PracticeUiCubit>(
      create: (_) => sl<PracticeUiCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final uiCubit = context.read<PracticeUiCubit>();
    return BlocConsumer<SessionBloc, SessionState>(
      listenWhen: (p, n) =>
          p.currentStreak != n.currentStreak ||
          (p.resultSummary == null) != (n.resultSummary == null),
      listener: (context, state) {
        uiCubit.handleStreak(state.currentStreak);
        if (state.resultSummary != null && !uiCubit.resultShown) {
          uiCubit.markResultShown();
          _runEndOfSessionFlow(context, uiCubit).whenComplete(() {
            uiCubit.clearResultShown();
          });
        }
      },
      builder: (context, state) {
        final uiState = context.watch<PracticeUiCubit>().state;
        final q = state.currentQuestion;
        final answered = state.hasAnsweredCurrent;
        final total = state.questions.length;
        return Column(
          children: [
            // Progress header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: question counter + streak + correct count + End
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          total == 0
                              ? 'Practice'
                              // Between batches the index runs past the current
                              // batch while the next one generates — show a
                              // loading label instead of an overflow like 21/20.
                              : state.questionStatus == LoadStatus.loading
                                  ? 'Generating…'
                                  : q == null
                                      ? 'Practice'
                                      : 'Question ${state.questionOffset + state.currentIndex + 1}',
                          style: AppTypography.labelLarge(c.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (uiState.streakMessage != null) ...[
                            _StreakBadge(
                              message: uiState.streakMessage!,
                              excellent: uiState.streakExcellent,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(LucideIcons.circleCheck, size: 16, color: c.accent),
                          const SizedBox(width: 6),
                          Text('${state.correctCount}',
                              style: AppTypography.bodySmall(c.textMuted)),
                          const SizedBox(width: 8),
                          // Report button — warning styled, mirrors React QuestionPractice
                          GestureDetector(
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (_) => const _FeedbackDialog(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: c.warningBg,
                                border: Border.all(color: c.warning),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.flag,
                                      size: 14, color: c.warning),
                                  const SizedBox(width: 4),
                                  Text('Report',
                                      style: AppTypography.mono(c.warning,
                                          size: 11)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 34),
                              side: BorderSide(color: c.danger),
                              foregroundColor: c.danger,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: state.finishing
                                ? null
                                : () => context.read<SessionBloc>().add(
                                      SessionFinished(
                                        userId: context
                                                .read<ProfileCubit>()
                                                .state
                                                .user
                                                ?.id ??
                                            '',
                                      ),
                                    ),
                            child: state.finishing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: c.danger),
                                  )
                                : Text('End',
                                    style: AppTypography.bodySmall(c.danger)
                                        .copyWith(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Row 2: chapter name + difficulty chip
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.bookOpen, size: 12, color: c.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          state.config.selectedChapter?.name ?? '',
                          style: AppTypography.mono(c.textMuted, size: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DifficultyChip(difficulty: state.config.difficulty),
                    ],
                  ),
                  // Row 3: compact session-progress bar + counter. Mirrors
                  // React QuestionPractice's `Q{i+1}/{n}` progress indicator,
                  // which the Flutter header was missing. Batch-relative, like
                  // React (currentIndex within the current questions batch).
                  if (total > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (state.currentIndex / total).clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: c.bgRaised,
                              valueColor: AlwaysStoppedAnimation(c.accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Q${(state.currentIndex + 1).clamp(1, total)}/$total',
                          style: AppTypography.mono(c.textMuted, size: 9),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: state.mastered
                  ? const _MasteredView()
                  // Show the generating loader for EVERY batch fetch (first batch
                  // and each subsequent one) — questionStatus is only `loading`
                  // while a batch is in flight, so the previous question must not
                  // linger on screen. A failed fetch shows the retry view.
                  : state.questionStatus == LoadStatus.loading
                  ? const _GeneratingView()
                  : state.questionStatus == LoadStatus.failure
                      ? _QuestionErrorView(
                          message: state.errorMessage ??
                              'Could not load questions. Please try again.',
                        )
                      : q == null
                          ? Center(
                              child: Text('No questions available.',
                                  style: AppTypography.bodyMedium(c.textMuted)))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _QuestionBubble(
                                question: q,
                                answered: answered,
                                feedback: state.feedback,
                                selectedAnswer: state.answers[q.id]?.answer,
                                onAnswer: (a) => context
                                    .read<SessionBloc>()
                                    .add(AnswerSubmitted(a)),
                              ),
                            ),
            ),
            // Footer actions
            if (q != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: answered
                            ? () => context
                                .read<SessionBloc>()
                                .add(const NextQuestionRequested())
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.textPrimary,
                          foregroundColor: c.bgPrimary,
                          disabledBackgroundColor: c.border,
                          disabledForegroundColor: c.textMuted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Next question', style: AppTypography.button(answered ? c.bgPrimary : c.textMuted)),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.arrowRight, size: 16, color: answered ? c.bgPrimary : c.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Transient streak badge shown in the header on a run of correct answers.
/// Auto-dismissed by the parent's timer (mirrors React's streak toast).
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.message, required this.excellent});
  final String message;
  final bool excellent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = excellent ? c.warning : c.danger;
    final bg = excellent ? c.warningBg : c.danger.withValues(alpha: 0.1);
    return TweenAnimationBuilder<double>(
      key: ValueKey(message),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 6), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(message,
            style: AppTypography.bodySmall(color)
                .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generating view — spinner + cycling status messages
// ---------------------------------------------------------------------------

class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  static const _messages = [
    'Generating your questions…',
    'Crafting the perfect challenge…',
    'Consulting the knowledge base…',
    'Tailoring questions to your level…',
    'Almost ready…',
    'Preparing your next set…',
    'AI is thinking hard…',
    'Curating questions for you…',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocProvider<GeneratingMessageCubit>(
      create: (_) => sl<GeneratingMessageCubit>(param1: _messages.length),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.accent, strokeWidth: 4),
            const SizedBox(height: 20),
            BlocBuilder<GeneratingMessageCubit, int>(
              builder: (context, index) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  _messages[index],
                  key: ValueKey(index),
                  style: AppTypography.bodyMedium(c.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mastery milestone — chapter tapped out (mirrors React's `mastered` state)
// ---------------------------------------------------------------------------

class _MasteredView extends StatelessWidget {
  const _MasteredView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.accentLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.trophy, size: 32, color: c.accent),
            ),
            const SizedBox(height: 16),
            Text('🏆 You’ve mastered this selection!',
                style: AppTypography.h4(c.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'You’ve answered every question we have here. Wrap up to see '
              'your results, or pick another chapter or difficulty to keep going.',
              style: AppTypography.bodySmall(c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<SessionBloc>().add(
                    SessionFinished(
                      userId:
                          context.read<ProfileCubit>().state.user?.id ?? '',
                    ),
                  ),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text('Finish & see results'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state shown when the batch fetch fails
// ---------------------------------------------------------------------------

class _QuestionErrorView extends StatelessWidget {
  const _QuestionErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.circleX, size: 28, color: c.danger),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: AppTypography.labelLarge(c.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: AppTypography.bodySmall(c.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context
                      .read<SessionBloc>()
                      .add(const BackToConfigRequested()),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.border),
                    foregroundColor: c.textSecondary,
                  ),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => context
                      .read<SessionBloc>()
                      .add(const QuestionBatchRetried()),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 14),
                      SizedBox(width: 6),
                      Text('Retry'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBubble extends StatefulWidget {
  const _QuestionBubble({
    required this.question,
    required this.answered,
    required this.feedback,
    required this.selectedAnswer,
    required this.onAnswer,
  });

  final Question question;
  final bool answered;
  final AnswerFeedback? feedback;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswer;

  @override
  State<_QuestionBubble> createState() => _QuestionBubbleState();
}

class _QuestionBubbleState extends State<_QuestionBubble> {
  final _blankController = TextEditingController();

  @override
  void dispose() {
    _blankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = widget.question;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: c.accentLight, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(LucideIcons.bot, size: 18, color: c.accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.accentLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Typewriter(
                  key: ValueKey(q.id),
                  text: q.text,
                  style: AppTypography.h4(c.textPrimary)
                      .copyWith(fontSize: 15, height: 1.55, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                QuestionAnswerWidgetFactoryRegistry.of(q.type).build(
                  context,
                  c,
                  q,
                  answered: widget.answered,
                  selectedAnswer: widget.selectedAnswer,
                  onAnswer: widget.onAnswer,
                  blankController: _blankController,
                ),
                if (widget.answered && widget.feedback != null) ...[
                  const SizedBox(height: 12),
                  _feedback(c, widget.feedback!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _feedback(AskAideColors c, AnswerFeedback f) {
    final color = f.isCorrect ? c.success : c.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(f.isCorrect ? LucideIcons.circleCheck : LucideIcons.circleX,
                  size: 16, color: color),
              const SizedBox(width: 8),
              Text(f.isCorrect ? 'Correct!' : 'Not quite',
                  style: AppTypography.labelLarge(color)),
            ],
          ),
          if (!f.isCorrect) ...[
            const SizedBox(height: 4),
            Text('Answer: ${f.correctAnswer}', style: AppTypography.bodySmall(c.textPrimary)),
          ],
          if (f.explanation != null && f.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(f.explanation!, style: AppTypography.bodySmall(c.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Types out [text] character-by-character (used for the question prompt).
class _Typewriter extends StatelessWidget {
  const _Typewriter({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TypewriterCubit>(
      create: (_) => sl<TypewriterCubit>(param1: text.length),
      child: BlocBuilder<TypewriterCubit, int>(
        builder: (context, count) =>
            Text(text.substring(0, count.clamp(0, text.length)), style: style),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Difficulty chip shown in the practice header
// ---------------------------------------------------------------------------

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.accentLight,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        difficulty.label.toUpperCase(),
        style: AppTypography.mono(c.accent, size: 9),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback dialog — mirrors React's FeedbackForm (Name* / Email / Feedback*)
// ---------------------------------------------------------------------------

class _FeedbackDialog extends StatelessWidget {
  const _FeedbackDialog();

  InputDecoration _fieldDecoration(AskAideColors c, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodySmall(c.textMuted),
      filled: true,
      fillColor: c.bgSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.accent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeedbackFormCubit>(
      create: (_) => sl<FeedbackFormCubit>(),
      child: Builder(builder: _buildDialog),
    );
  }

  Widget _buildDialog(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<FeedbackFormCubit>();
    return Dialog(
      backgroundColor: c.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<FeedbackFormCubit, FeedbackFormState>(
          builder: (context, state) => state.submitted
              ? _successView(context, c)
              : SingleChildScrollView(child: _formView(c, cubit, state)),
        ),
      ),
    );
  }

  Widget _successView(BuildContext context, AskAideColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.circleCheck, size: 40, color: c.success),
        const SizedBox(height: 16),
        Text('Thank you for your feedback!',
            style: AppTypography.h4(c.textPrimary),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Your feedback helps us improve AskAide for everyone.',
          style: AppTypography.bodySmall(c.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: AppTypography.button(c.accent)),
        ),
      ],
    );
  }

  Widget _formView(AskAideColors c, FeedbackFormCubit cubit, FeedbackFormState state) {
    return Builder(builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text('Share Your Feedback',
                  style: AppTypography.h4(c.textPrimary)),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(LucideIcons.x, size: 18, color: c.textMuted),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Help us make AskAide better for everyone',
            style: AppTypography.bodySmall(c.textMuted)),
        const SizedBox(height: 20),
        // Name (required)
        RichText(
          text: TextSpan(
            style: AppTypography.bodySmall(c.textPrimary)
                .copyWith(fontWeight: FontWeight.w500),
            children: [
              const TextSpan(text: 'Name '),
              TextSpan(text: '*', style: TextStyle(color: c.danger)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: cubit.name,
          style: AppTypography.bodyMedium(c.textPrimary),
          decoration: _fieldDecoration(c, 'Enter your name'),
        ),
        const SizedBox(height: 16),
        // Email (optional)
        RichText(
          text: TextSpan(
            style: AppTypography.bodySmall(c.textPrimary)
                .copyWith(fontWeight: FontWeight.w500),
            children: [
              const TextSpan(text: 'Email '),
              TextSpan(
                  text: '(optional)',
                  style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: cubit.email,
          style: AppTypography.bodyMedium(c.textPrimary),
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDecoration(c, 'your@email.com'),
        ),
        const SizedBox(height: 16),
        // Feedback (required)
        RichText(
          text: TextSpan(
            style: AppTypography.bodySmall(c.textPrimary)
                .copyWith(fontWeight: FontWeight.w500),
            children: [
              const TextSpan(text: 'Your Feedback '),
              TextSpan(text: '*', style: TextStyle(color: c.danger)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: cubit.feedback,
          style: AppTypography.bodyMedium(c.textPrimary),
          maxLines: 4,
          decoration: _fieldDecoration(
              c, "Tell us what's on your mind…"),
        ),
        // Error box
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.danger.withValues(alpha: 0.1),
              border: Border.all(color: c.danger.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(state.error!,
                style: AppTypography.bodySmall(c.danger)),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.submitting ? null : cubit.submit,
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: c.border,
              disabledForegroundColor: c.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: state.submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.send, size: 15, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Submit Feedback',
                          style: AppTypography.button(Colors.white)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Your feedback is anonymous unless you provide your email',
            style: AppTypography.bodySmall(c.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ));
  }
}
