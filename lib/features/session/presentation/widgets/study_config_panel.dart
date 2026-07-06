import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/study_enums.dart';
import '../../domain/entities/study_taxonomy.dart';
import '../bloc/session_bloc.dart';
import '../cubit/picker_search_cubit.dart';

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
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  const SizedBox(height: AppSpacing.lg),

                  _StepBar(currentStep: step),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.errorMessage != null) ...[
                    _ErrorAlert(message: state.errorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Configuration card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SearchableDropdown<ClassOption>(
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
                          const SizedBox(height: AppSpacing.sm),
                          _SearchableDropdown<SubjectOption>(
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
                          const SizedBox(height: AppSpacing.sm),
                          _SearchableDropdown<ChapterOption>(
                            label: 'Chapter',
                            hint: 'Choose a chapter',
                            value: cfg.selectedChapter,
                            items: state.chapters,
                            itemLabel: (o) =>
                                o.number != null ? '${o.number}. ${o.name}' : o.name,
                            loading: state.taxonomyStatus == LoadStatus.loading &&
                                state.chapters.isEmpty,
                            isDisabled: (o) => o.comingSoon || !o.isStartable,
                            disabledLabel: (_) => 'Coming Soon',
                            onChanged: (o) =>
                                context.read<SessionBloc>().add(ChapterSelected(o)),
                          ),
                        ],
                        if (step >= 4) ...[
                          const SizedBox(height: AppSpacing.md),
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
                              const SizedBox(width: AppSpacing.sm),
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
                          const SizedBox(height: AppSpacing.lg),
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

                  const SizedBox(height: AppSpacing.xl),
                  // Quick tips
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
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

// ---------------------------------------------------------------------------
// Searchable field — tapping opens a themed bottom-sheet picker
// ---------------------------------------------------------------------------

class _SearchableDropdown<T> extends StatelessWidget {
  const _SearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.loading = false,
    this.isDisabled,
    this.disabledLabel,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final bool loading;
  final bool Function(T)? isDisabled;
  /// Returns a pill badge label for a disabled item, or null for no badge.
  final String? Function(T)? disabledLabel;

  void _openSheet(BuildContext context) {
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet<T>(
        title: label,
        items: items,
        itemLabel: itemLabel,
        isDisabled: isDisabled,
        disabledLabel: disabledLabel,
      ),
    ).then((selected) {
      if (selected != null) onChanged(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasValue = value != null;

    final fieldDecoration = BoxDecoration(
      color: c.bgRaised,
      border: Border.all(color: c.border),
      borderRadius: AppRadii.cardR,
    );
    const fieldPadding =
        EdgeInsets.symmetric(horizontal: 12, vertical: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        if (loading)
          Container(
            decoration: fieldDecoration,
            padding: fieldPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(hint, style: AppTypography.bodyLarge(c.textMuted)),
                ),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () => _openSheet(context),
            child: Container(
              decoration: fieldDecoration,
              padding: fieldPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? itemLabel(value as T) : hint,
                      style: AppTypography.bodyLarge(
                          hasValue ? c.textPrimary : c.textMuted),
                    ),
                  ),
                  Icon(LucideIcons.chevronDown, size: 18, color: c.textMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom-sheet picker used by _SearchableDropdown
// ---------------------------------------------------------------------------

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.itemLabel,
    this.isDisabled,
    this.disabledLabel,
  });

  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final bool Function(T)? isDisabled;
  final String? Function(T)? disabledLabel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PickerSearchCubit>(
      create: (_) => sl<PickerSearchCubit>(),
      child: Builder(builder: _buildSheet),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final c = context.colors;
    final mq = MediaQuery.of(context);
    final query = context.watch<PickerSearchCubit>().state;
    final filtered = query.isEmpty
        ? items
        : items
            .where((i) => itemLabel(i).toLowerCase().contains(query.toLowerCase()))
            .toList();

    // Hard ceiling: the smaller of 65 % of screen height or the space that
    // remains above the keyboard. Keeps the sheet partial when keyboard is
    // hidden and prevents overflow when it appears.
    final availableHeight = (mq.size.height * 0.65)
        .clamp(0.0, mq.size.height - mq.viewInsets.bottom);

    return Padding(
      // Lift the sheet above the keyboard when the search field is focused.
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableHeight),
        child: Container(
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border(
              top: BorderSide(color: c.border),
              left: BorderSide(color: c.border),
              right: BorderSide(color: c.border),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title + close row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: AppTypography.mono(c.accent, size: 11),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, size: 18, color: c.textMuted),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: AppTypography.bodyMedium(c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(LucideIcons.search, size: 16, color: c.textMuted),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  filled: true,
                  fillColor: c.bgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.modalR,
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.modalR,
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.modalR,
                    borderSide: BorderSide(color: c.accent),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => context.read<PickerSearchCubit>().setQuery(v),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Divider(height: 1, color: c.border),
            // Flexible absorbs whatever space the fixed elements leave, so
            // the Column never overflows even when the keyboard is showing.
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No results',
                          style: AppTypography.bodySmall(c.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, idx) {
                        final item = filtered[idx];
                        final disabled = isDisabled?.call(item) ?? false;
                        return _PickerItem(
                          label: itemLabel(item),
                          disabled: disabled,
                          badgeLabel: disabled
                              ? disabledLabel?.call(item)
                              : null,
                          onTap: disabled
                              ? null
                              : () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _PickerItem extends StatelessWidget {
  const _PickerItem({
    required this.label,
    required this.disabled,
    this.badgeLabel,
    this.onTap,
  });

  final String label;
  final bool disabled;
  final String? badgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium(
                    disabled ? c.textMuted : c.textPrimary),
              ),
            ),
            if (badgeLabel != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: c.textMuted.withValues(alpha: 0.12),
                  borderRadius: AppRadii.pillR,
                ),
                child: Text(
                  badgeLabel!,
                  style: AppTypography.mono(c.textMuted, size: 9),
                ),
              ),
            ] else if (!disabled) ...[
              Icon(LucideIcons.chevronRight, size: 16, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step bar
// ---------------------------------------------------------------------------

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
        borderRadius: AppRadii.cardR,
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
          const SizedBox(height: AppSpacing.xs),
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

/// Like [_SearchableDropdown] but for non-null enum selections (no search needed).
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
            borderRadius: AppRadii.cardR,
          ),
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
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
          shape: RoundedRectangleBorder(borderRadius: AppRadii.sectionR),
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
                  const SizedBox(width: AppSpacing.xs),
                  Text('Start Learning',
                      style: AppTypography.button(active ? c.bgPrimary : c.textMuted)),
                  const SizedBox(width: AppSpacing.xs),
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
        borderRadius: AppRadii.cardR,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: 16, color: c.danger),
          const SizedBox(width: AppSpacing.sm),
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
