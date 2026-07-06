import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/question_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/question.dart';

/// Factory Method for building the answer-capture widget for a question,
/// keyed by [QuestionType]. Adding a new question type means adding one
/// factory here — [_QuestionBubbleState] doesn't need to branch on type.
abstract class QuestionAnswerWidgetFactory {
  const QuestionAnswerWidgetFactory();

  Widget build(
    BuildContext context,
    AskAideColors c,
    Question q, {
    required bool answered,
    required String? selectedAnswer,
    required ValueChanged<String> onAnswer,
    required TextEditingController blankController,
  });
}

class McqAnswerWidgetFactory extends QuestionAnswerWidgetFactory {
  const McqAnswerWidgetFactory();

  @override
  Widget build(
    BuildContext context,
    AskAideColors c,
    Question q, {
    required bool answered,
    required String? selectedAnswer,
    required ValueChanged<String> onAnswer,
    required TextEditingController blankController,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _optionButton(c, q, q.options[i], i, answered, selectedAnswer, onAnswer),
          ),
      ],
    );
  }

  Widget _optionButton(
    AskAideColors c,
    Question q,
    String option,
    int idx,
    bool answered,
    String? selectedAnswer,
    ValueChanged<String> onAnswer,
  ) {
    final show = answered;
    final isCorrect = show && option == q.correctAnswer;
    final isWrong = show && option != q.correctAnswer && option == selectedAnswer;

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
      onTap: show ? null : () => onAnswer(option),
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
}

class FillBlankAnswerWidgetFactory extends QuestionAnswerWidgetFactory {
  const FillBlankAnswerWidgetFactory();

  @override
  Widget build(
    BuildContext context,
    AskAideColors c,
    Question q, {
    required bool answered,
    required String? selectedAnswer,
    required ValueChanged<String> onAnswer,
    required TextEditingController blankController,
  }) {
    if (answered) {
      return Text('Your answer: ${selectedAnswer ?? ''}',
          style: AppTypography.bodyMedium(c.textPrimary));
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: blankController,
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
              if (v.trim().isNotEmpty) onAnswer(v.trim());
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            final v = blankController.text.trim();
            if (v.isNotEmpty) onAnswer(v);
          },
          icon: Icon(LucideIcons.send, color: c.accent),
        ),
      ],
    );
  }
}

class QuestionAnswerWidgetFactoryRegistry {
  const QuestionAnswerWidgetFactoryRegistry._();

  static const Map<QuestionType, QuestionAnswerWidgetFactory> _factories = {
    QuestionType.mcq: McqAnswerWidgetFactory(),
    QuestionType.fillInTheBlank: FillBlankAnswerWidgetFactory(),
  };

  static QuestionAnswerWidgetFactory of(QuestionType type) => _factories[type]!;
}
