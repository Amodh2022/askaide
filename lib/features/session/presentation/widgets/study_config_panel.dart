import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/study_enums.dart';
import '../../domain/entities/study_taxonomy.dart';
import '../bloc/session_bloc.dart';

/// The `/study` configuration funnel: eyebrow + heading, a 4-step progress bar,
/// cascading Class → Subject → Chapter dropdowns, then Question Type +
/// Difficulty and the Start button — revealed step by step. Mirrors the
/// frontend's StudyConfig.
class StudyConfigPanel extends StatelessWidget {
  const StudyConfigPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final cfg = state.config;
        final step = cfg.selectedChapter != null
            ? 4
            : cfg.selectedSubject != null
                ? 3
                : cfg.selectedClass != null
                    ? 2
                    : 1;
        final firstName = context.select<ProfileCubit, String>((p) {
          final n = p.state.user?.name ?? '';
          return n.isEmpty ? 'student' : n.split(' ').first;
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('— STUDY', style: AppTypography.sectionLabel(c.accent)),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 30),
                      children: [
                        const TextSpan(text: 'What will you '),
                        TextSpan(
                            text: 'practise',
                            style: AppTypography.serifEmphasis(c.textPrimary, size: 30)),
                        TextSpan(text: ' today, $firstName?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Pick a chapter and start working.',
                      style: AppTypography.bodyMedium(c.textMuted)),
                  const SizedBox(height: 24),

                  _StepBar(currentStep: step),
                  const SizedBox(height: 24),

                  if (state.errorMessage != null) ...[
                    _ErrorAlert(message: state.errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // Configuration card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Dropdown<ClassOption>(
                          label: 'Class',
                          hint: 'Select class',
                          value: cfg.selectedClass,
                          items: state.classes,
                          itemLabel: (o) => o.name,
                          loading: state.taxonomyStatus == LoadStatus.loading &&
                              state.classes.isEmpty,
                          onChanged: (o) =>
                              context.read<SessionBloc>().add(ClassSelected(o)),
                        ),
                        if (step >= 2) ...[
                          const SizedBox(height: 12),
                          _Dropdown<SubjectOption>(
                            label: 'Subject',
                            hint: 'Select subject',
                            value: cfg.selectedSubject,
                            items: state.subjects,
                            itemLabel: (o) => o.name,
                            loading: state.taxonomyStatus == LoadStatus.loading &&
                                state.subjects.isEmpty,
                            onChanged: (o) =>
                                context.read<SessionBloc>().add(SubjectSelected(o)),
                          ),
                        ],
                        if (step >= 3) ...[
                          const SizedBox(height: 12),
                          _Dropdown<ChapterOption>(
                            label: 'Chapter',
                            hint: 'Choose a chapter',
                            value: cfg.selectedChapter,
                            items: state.chapters,
                            itemLabel: (o) =>
                                o.number != null ? '${o.number}. ${o.name}' : o.name,
                            loading: state.taxonomyStatus == LoadStatus.loading &&
                                state.chapters.isEmpty,
                            onChanged: (o) =>
                                context.read<SessionBloc>().add(ChapterSelected(o)),
                          ),
                        ],
                        if (step >= 4) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _EnumDropdown<QuestionType>(
                                  label: 'Question Type',
                                  value: cfg.questionType,
                                  items: QuestionType.values,
                                  itemLabel: (t) => t.label,
                                  onChanged: (t) => context
                                      .read<SessionBloc>()
                                      .add(QuestionTypeSelected(t)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EnumDropdown<Difficulty>(
                                  label: 'Difficulty',
                                  value: cfg.difficulty,
                                  items: Difficulty.values,
                                  itemLabel: (d) => switch (d) {
                                    Difficulty.easy => '🟢 Easy',
                                    Difficulty.medium => '🟡 Medium',
                                    Difficulty.hard => '🔴 Hard',
                                  },
                                  onChanged: (d) => context
                                      .read<SessionBloc>()
                                      .add(DifficultySelected(d)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _StartButton(
                            enabled: cfg.isComplete,
                            loading: state.questionStatus == LoadStatus.loading,
                            onPressed: () => context.read<SessionBloc>().add(
                                  PracticeStarted(
                                    userId: context
                                            .read<ProfileCubit>()
                                            .state
                                            .user
                                            ?.id ??
                                        '',
                                  ),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Quick tips
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: const [
                      _Tip(icon: LucideIcons.clock, label: 'Sessions auto-save progress'),
                      _Tip(icon: LucideIcons.zap, label: 'AI-powered questions'),
                      _Tip(icon: LucideIcons.brain, label: 'Adaptive difficulty'),
                    ],
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

class _StepBar extends StatelessWidget {
  const _StepBar({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const labels = ['Class', 'Subject', 'Chapter', 'Start'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESS', style: AppTypography.mono(c.textMuted, size: 9)),
              Text('STEP $currentStep OF 4', style: AppTypography.mono(c.textMuted, size: 9)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final done = (i ~/ 2) + 1 < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: done ? c.accent : c.border,
                  ),
                );
              }
              final idx = i ~/ 2;
              final done = idx + 1 < currentStep;
              final active = idx + 1 == currentStep;
              return Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: (done || active) ? c.accent : c.bgSecondary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: done
                        ? Icon(LucideIcons.check, size: 11, color: c.bgCard)
                        : Text('${idx + 1}',
                            style: AppTypography.mono(
                                (done || active) ? c.bgCard : c.textMuted,
                                size: 9)),
                  ),
                  const SizedBox(width: 6),
                  Text(labels[idx],
                      style: AppTypography.mono(
                          (done || active) ? c.accent : c.textMuted,
                          size: 9)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// A labeled dropdown over a list of value-objects.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.loading = false,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.bgRaised,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: AppTypography.bodyMedium(c.textMuted)),
              icon: loading
                  ? SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: c.textMuted))
                  : Icon(LucideIcons.chevronDown, size: 18, color: c.textMuted),
              dropdownColor: c.bgCard,
              style: AppTypography.bodyLarge(c.textPrimary),
              items: items
                  .map((o) => DropdownMenuItem<T>(value: o, child: Text(itemLabel(o))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Like [_Dropdown] but for non-null enum selections.
class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.bgRaised,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(LucideIcons.chevronDown, size: 18, color: c.textMuted),
              dropdownColor: c.bgCard,
              style: AppTypography.bodyLarge(c.textPrimary),
              items: items
                  .map((o) => DropdownMenuItem<T>(value: o, child: Text(itemLabel(o))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.enabled, required this.loading, required this.onPressed});
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: active ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: c.textPrimary,
          foregroundColor: c.bgPrimary,
          disabledBackgroundColor: c.border,
          disabledForegroundColor: c.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: c.bgPrimary)),
                  const SizedBox(width: 10),
                  Text('Starting...', style: AppTypography.button(c.bgPrimary)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.sparkles, size: 18, color: active ? c.bgPrimary : c.textMuted),
                  const SizedBox(width: 8),
                  Text('Start Learning',
                      style: AppTypography.button(active ? c.bgPrimary : c.textMuted)),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 18, color: active ? c.bgPrimary : c.textMuted),
                ],
              ),
      ),
    );
  }
}

class _ErrorAlert extends StatelessWidget {
  const _ErrorAlert({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.08),
        border: Border.all(color: c.danger),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: 16, color: c.danger),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppTypography.bodySmall(c.danger))),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall(c.textSecondary).copyWith(fontSize: 12)),
      ],
    );
  }
}
