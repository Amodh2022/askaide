import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/study_enums.dart';
import '../bloc/session_bloc.dart';
import 'nps_survey_dialog.dart';
import 'session_result_modal.dart';

/// The in-session practice view: a progress header, the AI question bubble with
/// MCQ options (or a fill-in-the-blank input), instant correct/wrong feedback,
/// and Next / End controls. Mirrors the frontend QuestionPractice + CurrentQuestion.
class PracticePanel extends StatefulWidget {
  const PracticePanel({super.key});

  @override
  State<PracticePanel> createState() => _PracticePanelState();
}

class _PracticePanelState extends State<PracticePanel> {
  // --- Transient streak badge (mirrors React's Variable Rewards) ---
  int _prevStreak = 0;
  String? _streakMessage;
  bool _streakExcellent = false;
  Timer? _streakTimer;

  // Guards so the end-of-session modal flow runs exactly once.
  bool _resultShown = false;

  @override
  void dispose() {
    _streakTimer?.cancel();
    super.dispose();
  }

  void _handleStreak(int streak) {
    // Only fire when the streak grows past a threshold (matches React).
    if (streak > _prevStreak && streak >= 3) {
      setState(() {
        if (streak >= 5) {
          _streakMessage = '🌟 Excellent streak!';
          _streakExcellent = true;
        } else {
          _streakMessage = '🔥 On fire!';
          _streakExcellent = false;
        }
      });
      _streakTimer?.cancel();
      _streakTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _streakMessage = null);
      });
    }
    _prevStreak = streak;
  }

  Future<void> _runEndOfSessionFlow() async {
    // Capture dependencies up front so we never touch a context across an await.
    final bloc = context.read<SessionBloc>();
    final userId = context.read<ProfileCubit>().state.user?.id ?? '';
    final summary = bloc.state.resultSummary;
    if (summary == null) return;

    // 1) Result modal summarising the session.
    await showSessionResultModal(context, summary);
    if (!mounted) return;

    // 2) Post-session NPS survey — only when the server says the user is due
    //    one (mirrors React's checkNpsEligibility gate) and not already shown.
    if (bloc.state.npsEligible && !bloc.state.npsHandled) {
      final result = await showNpsSurvey(context);
      if (!mounted) return;
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
    final c = context.colors;
    return BlocConsumer<SessionBloc, SessionState>(
      listenWhen: (p, n) =>
          p.currentStreak != n.currentStreak ||
          (p.resultSummary == null) != (n.resultSummary == null),
      listener: (context, state) {
        _handleStreak(state.currentStreak);
        if (state.resultSummary != null && !_resultShown) {
          _resultShown = true;
          _runEndOfSessionFlow().whenComplete(() {
            if (mounted) _resultShown = false;
          });
        }
      },
      builder: (context, state) {
        final q = state.currentQuestion;
        final answered = state.hasAnsweredCurrent;
        final total = state.questions.length;
        return Column(
          children: [
            // Progress header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      total == 0
                          ? 'Practice'
                          : 'Question ${state.currentIndex + 1} of $total',
                      style: AppTypography.labelLarge(c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_streakMessage != null) ...[
                        _StreakBadge(
                          message: _streakMessage!,
                          excellent: _streakExcellent,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(LucideIcons.circleCheck, size: 16, color: c.accent),
                      const SizedBox(width: 6),
                      Text('${state.correctCount}',
                          style: AppTypography.bodySmall(c.textMuted)),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36)),
                        onPressed: () => context.read<SessionBloc>().add(
                              SessionFinished(
                                userId: context
                                        .read<ProfileCubit>()
                                        .state
                                        .user
                                        ?.id ??
                                    '',
                              ),
                            ),
                        child: Text('End', style: AppTypography.bodySmall(c.danger)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.questionStatus == LoadStatus.loading && q == null
                  ? _GeneratingIndicator(color: c.accent, textColor: c.textMuted)
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
                            onAnswer: (a) =>
                                context.read<SessionBloc>().add(AnswerSubmitted(a)),
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

/// Shown while the server AI-generates the next batch. Cycles through status
/// messages like the frontend's TypewriterLoop in QuestionPractice.
class _GeneratingIndicator extends StatefulWidget {
  const _GeneratingIndicator({required this.color, required this.textColor});
  final Color color;
  final Color textColor;

  @override
  State<_GeneratingIndicator> createState() => _GeneratingIndicatorState();
}

class _GeneratingIndicatorState extends State<_GeneratingIndicator> {
  static const _messages = [
    'Analyzing your performance…',
    'Calibrating difficulty…',
    'Crafting new questions…',
    'Finalizing your adaptation…',
  ];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted) setState(() => _i = (_i + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: widget.color),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _messages[_i],
              key: ValueKey(_i),
              style: AppTypography.bodyMedium(widget.textColor),
            ),
          ),
        ],
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
                if (q.type == QuestionType.mcq)
                  ..._options(c, q)
                else
                  _fillInput(c, q),
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

  List<Widget> _options(AskAideColors c, Question q) {
    return [
      for (var i = 0; i < q.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _optionButton(c, q, q.options[i], i),
        ),
    ];
  }

  Widget _optionButton(AskAideColors c, Question q, String option, int idx) {
    final show = widget.answered;
    final isCorrect = show && option == q.correctAnswer;
    final isWrong = show && option != q.correctAnswer && option == widget.selectedAnswer;

    Color border = c.border;
    Color bg = c.bgCard;
    Color fg = c.textPrimary;
    if (isCorrect) {
      border = c.accent;
      bg = c.accentLight;
      fg = c.accent;
    } else if (isWrong) {
      border = c.danger;
      bg = c.danger.withValues(alpha: 0.08);
      fg = c.danger;
    }

    return InkWell(
      onTap: show ? null : () => widget.onAnswer(option),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: isCorrect || isWrong ? 1.5 : 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: isCorrect
                  ? Icon(LucideIcons.circleCheck, size: 15, color: c.accent)
                  : isWrong
                      ? Icon(LucideIcons.circleX, size: 15, color: c.danger)
                      : Container(
                          decoration: BoxDecoration(
                              color: c.border, borderRadius: BorderRadius.circular(3)),
                          alignment: Alignment.center,
                          child: Text('${idx + 1}',
                              style: AppTypography.mono(c.textMuted, size: 10)),
                        ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(option,
                    style: AppTypography.bodyMedium(fg).copyWith(fontSize: 13.5))),
          ],
        ),
      ),
    );
  }

  Widget _fillInput(AskAideColors c, Question q) {
    if (widget.answered) {
      return Text('Your answer: ${widget.selectedAnswer ?? ''}',
          style: AppTypography.bodyMedium(c.textPrimary));
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _blankController,
            style: AppTypography.bodyLarge(c.textPrimary),
            cursorColor: c.accent,
            decoration: InputDecoration(
              filled: true,
              fillColor: c.bgCard,
              hintText: 'Type your answer',
              hintStyle: AppTypography.bodyMedium(c.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.accent)),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) widget.onAnswer(v.trim());
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            final v = _blankController.text.trim();
            if (v.isNotEmpty) widget.onAnswer(v);
          },
          icon: Icon(LucideIcons.send, color: c.accent),
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
class _Typewriter extends StatefulWidget {
  const _Typewriter({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter> {
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _count = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) return;
      if (_count >= widget.text.length) {
        t.cancel();
      } else {
        setState(() => _count++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.text.substring(0, _count.clamp(0, widget.text.length)),
        style: widget.style);
  }
}
