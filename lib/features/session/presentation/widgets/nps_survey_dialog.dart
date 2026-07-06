import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/nps_survey_cubit.dart';

/// Result of the NPS survey: a 0–10 recommendation [score] and optional
/// free-text [comment].
class NpsResult {
  const NpsResult({required this.score, this.comment});
  final int score;
  final String? comment;
}

/// Shows the post-session NPS survey (mirrors React's NpsSurvey):
/// "How likely are you to recommend AskAide to a classmate?" on a 0–10 scale,
/// with an optional comment. Resolves to an [NpsResult] on submit, or `null`
/// if the user dismisses it without answering.
Future<NpsResult?> showNpsSurvey(BuildContext context) {
  return showDialog<NpsResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _NpsSurveyDialog(),
  );
}

class _NpsSurveyDialog extends StatelessWidget {
  const _NpsSurveyDialog();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NpsSurveyCubit>(
      create: (_) => sl<NpsSurveyCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  void _submit(BuildContext context, NpsSurveyCubit cubit) {
    final result = cubit.submit();
    if (result == null) return;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) Navigator.of(context).pop(result);
    });
  }

  Color _scoreColor(AskAideColors c, int? selected, int val) {
    if (selected == null || val > selected) return c.bgSecondary;
    if (selected <= 3) return c.error;
    if (selected <= 6) return c.warning;
    return c.success;
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<NpsSurveyCubit>();
    return BlocBuilder<NpsSurveyCubit, NpsSurveyState>(
      builder: (context, state) {
    if (state.submitted) {
      return Dialog(
        backgroundColor: c.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🙏', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text('Thank you!', style: AppTypography.h4(c.textPrimary)),
              const SizedBox(height: 4),
              Text('Your feedback helps us improve',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(c.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: c.bgCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.star, size: 18, color: c.accent),
                  const SizedBox(width: 8),
                  Text('Quick Question',
                      style: AppTypography.labelLarge(c.textPrimary)),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(LucideIcons.x, size: 16, color: c.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('How likely are you to recommend AskAide to a classmate?',
                  style: AppTypography.bodyMedium(c.textSecondary)),
              const SizedBox(height: 16),
              // 0–10 score picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var val = 0; val <= 10; val++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: GestureDetector(
                          onTap: () => cubit.selectScore(val),
                          child: Container(
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _scoreColor(c, state.score, val),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: state.score == val ? c.accent : c.borderSubtle,
                                width: state.score == val ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              '$val',
                              style: AppTypography.bodySmall(
                                state.score != null && val <= state.score!
                                    ? Colors.white
                                    : c.textMuted,
                              ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Not at all',
                      style: AppTypography.bodySmall(c.textMuted)
                          .copyWith(fontSize: 10)),
                  Text('Very likely',
                      style: AppTypography.bodySmall(c.textMuted)
                          .copyWith(fontSize: 10)),
                ],
              ),
              if (state.score != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: cubit.comment,
                  maxLength: 200,
                  style: AppTypography.bodyMedium(c.textPrimary),
                  cursorColor: c.accent,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.bgSecondary,
                    isDense: true,
                    counterText: '',
                    hintText: 'Any thoughts? (optional)',
                    hintStyle: AppTypography.bodySmall(c.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: c.accent)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.score == null ? null : () => _submit(context, cubit),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: c.bgSecondary,
                    disabledForegroundColor: c.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.send,
                          size: 16,
                          color: state.score == null ? c.textMuted : Colors.white),
                      const SizedBox(width: 8),
                      Text('Submit feedback',
                          style: AppTypography.button(
                              state.score == null ? c.textMuted : Colors.white)),
                    ],
                  ),
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
