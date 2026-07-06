import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/page_scroll_scaffold.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../session/domain/entities/study_taxonomy.dart' as tax;
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../data/progress_models.dart';
import '../../data/progress_repository.dart';
import '../cubit/ai_coach_cubit.dart';
import '../cubit/progress_cubit.dart';

/// Shimmer skeleton matching the progress page's layout: selectors, gauge cards,
/// chapter health bar, and chapter list.
class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown selectors
          LayoutBuilder(
            builder: (context, cons) {
              final wide = cons.maxWidth > 560;
              final dd = Container(
                height: 52,
                decoration: BoxDecoration(
                  color: c.bgCard,
                  border: Border.all(color: c.border),
                  borderRadius: AppRadii.cardR,
                ),
              );
              if (wide) {
                return Row(
                  children: [
                    SizedBox(width: 260, child: dd),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(width: 260, child: dd),
                  ],
                );
              }
              return Column(children: [dd, const SizedBox(height: AppSpacing.sm), dd]);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          // Gauge cards row (2 side by side)
          LayoutBuilder(
            builder: (context, cons) {
              final wide = cons.maxWidth > 560;
              final card = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.bgCard,
                  border: Border.all(color: c.border),
                  borderRadius: AppRadii.cardR,
                ),
                child: Column(
                  children: [
                    const SkeletonBox(width: 80, height: 10),
                    const SizedBox(height: AppSpacing.xs),
                    const SkeletonBox(width: 100, height: 14),
                    const SizedBox(height: 14),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: c.bgRaised,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SkeletonBox(width: 120, height: 12),
                  ],
                ),
              );
              if (wide) {
                return Row(children: [
                  Expanded(child: card),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: card),
                ]);
              }
              return Column(children: [card, const SizedBox(height: AppSpacing.md), card]);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Chapter health card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: AppRadii.cardR,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: c.bgRaised,
                            borderRadius: AppRadii.cardR),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const SkeletonBox(width: 110, height: 10),
                    ]),
                    const SkeletonBox(width: 80, height: 18, radius: 99),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.bgRaised,
                    borderRadius: AppRadii.pillR,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(right: 18),
                      child: Row(
                        children: [
                          SkeletonCircle(size: 10),
                          SizedBox(width: 6),
                          SkeletonBox(width: 60, height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // AI coach card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: AppRadii.cardR,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: c.bgRaised,
                      borderRadius: AppRadii.sectionR),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 14),
                      SizedBox(height: AppSpacing.xxs),
                      SkeletonBox(width: 220, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Chapter section header
          Row(
            children: [
              const SkeletonBox(width: 80, height: 18),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 22,
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  borderRadius: AppRadii.pillR,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Chapter cards
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _ChapterCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single chapter card skeleton matching [_ChapterCard].
class _ChapterCardSkeleton extends StatelessWidget {
  const _ChapterCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 80, height: 10),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  borderRadius: AppRadii.pillR,
                ),
              ),
              const Spacer(),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: c.bgRaised, borderRadius: AppRadii.cardR),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const SkeletonBox(width: 200, height: 16),
          const SizedBox(height: AppSpacing.xxs),
          const SkeletonBox(width: 160, height: 11),
          const SizedBox(height: 14),
          // Coverage bar
          const SkeletonBox(width: 60, height: 10),
          const SizedBox(height: AppSpacing.xxs),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: AppRadii.pillR,
            ),
          ),
          const SizedBox(height: 10),
          // Mastery bar
          const SkeletonBox(width: 55, height: 10),
          const SizedBox(height: AppSpacing.xxs),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: AppRadii.pillR,
            ),
          ),
          const SizedBox(height: 14),
          // Practice button
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 170,
              height: 36,
              decoration: BoxDecoration(
                color: c.bgRaised,
                borderRadius: AppRadii.pillR,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `/progress` — class/subject selectors → subject summary (coverage + mastery +
/// chapter-health) → chapter list → chapter detail with topic breakdown. Mirrors
/// the frontend Progress page.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProgressCubit>(
      create: (_) => sl<ProgressCubit>()
        ..init(context.read<ProfileCubit>().state.user?.id ?? ''),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The Progress page stays mounted (its shell branch lives in an
    // IndexedStack), so this listener fires even while the user is on the Study
    // tab. When a session launched from here is dismissed (originRoute cleared),
    // return to this page and refresh the chapter the user just practised.
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (p, n) =>
          p.originRoute == RoutePaths.progress && n.originRoute == null,
      listener: (context, _) {
        context.go(RoutePaths.progress);
        context.read<ProgressCubit>().refreshSelectedSubject();
      },
      child: RefreshIndicator(
        onRefresh: () async {
          final userId = context.read<ProfileCubit>().state.user?.id ?? '';
          if (userId.isNotEmpty) {
            await context.read<ProgressCubit>().init(userId);
          }
        },
        child: PageScrollScaffold(
          maxWidth: 920,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
                  Text('PROGRESS',
                      style: AppTypography.sectionLabel(c.textMuted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text("How far you've come.",
                      style: AppTypography.h1(c.textPrimary)
                          .copyWith(fontSize: 30)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Track your coverage and mastery chapter by chapter.',
                      style: AppTypography.bodyMedium(c.textMuted)),
                  const SizedBox(height: 28),
                  BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, state) {
                      final cubit = context.read<ProgressCubit>();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class / subject selectors
                          if (state.classes.isNotEmpty)
                            LayoutBuilder(builder: (context, cons) {
                              final wide = cons.maxWidth > 560;
                              final classDd = _Dropdown(
                                label: 'Select Class',
                                value: state.selectedClassId,
                                items: [
                                  for (final c in state.classes) (c.id, c.name)
                                ],
                                onChanged: (v) =>
                                    v != null ? cubit.selectClass(v) : null,
                              );
                              final subjectDd = state.subjects.isEmpty
                                  ? const SizedBox.shrink()
                                  : _Dropdown(
                                      label: 'Select Subject',
                                      value: state.selectedSubjectId,
                                      items: [
                                        for (final s in state.subjects)
                                          (s.id, s.name)
                                      ],
                                      onChanged: (v) => v != null
                                          ? cubit.selectSubject(v)
                                          : null,
                                    );
                              return wide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(width: 260, child: classDd),
                                        const SizedBox(width: AppSpacing.md),
                                        SizedBox(width: 260, child: subjectDd),
                                      ],
                                    )
                                  : Column(children: [
                                      classDd,
                                      const SizedBox(height: AppSpacing.sm),
                                      subjectDd,
                                    ]);
                            }),
                          const SizedBox(height: AppSpacing.lg),
                          _body(context, state),
                        ],
                      );
                    },
                  ),
                ],
            ),
          ),
        );
  }

  Widget _body(BuildContext context, ProgressState state) {
    final c = context.colors;
    switch (state.status) {
      case ProgressStatus.loading:
        return const _ProgressSkeleton();
      case ProgressStatus.empty:
        if (state.classes.isEmpty) {
          return _EmptyCard(
            icon: LucideIcons.bookOpen,
            title: 'No Classes Configured',
            hint:
                'Please configure your class and subjects first to track your progress.',
            ctaLabel: 'Go to Settings',
            onCta: () => context.go(RoutePaths.settings),
          );
        }
        if (state.subjects.isEmpty) {
          return const _EmptyCard(
            icon: LucideIcons.bookOpen,
            title: 'No Subjects Available',
            hint: 'This class has no subjects configured yet.',
          );
        }
        return _EmptyCard(
          icon: LucideIcons.circlePlay,
          title: 'Start Your Learning Journey',
          hint:
              "You haven't practiced any questions in this subject yet. Start a study session to track your progress!",
          ctaLabel: 'Start Studying',
          onCta: () => context.go(RoutePaths.study),
        );
      case ProgressStatus.loaded:
        final data = state.data;
        if (data == null) return const SizedBox.shrink();
        final chapter = state.selectedChapter;
        if (chapter != null) {
          return _ChapterDetail(chapter: chapter);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubjectSummary(data: data),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text('Chapters', style: AppTypography.h3(c.textPrimary)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accentLight,
                    borderRadius: AppRadii.pillR,
                  ),
                  child: Text('${data.chapters.length}',
                      style: AppTypography.mono(c.textMuted, size: 11)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final ch in data.chapters)
              _ChapterCard(
                chapter: ch,
                onOpen: () => context.read<ProgressCubit>().openChapter(ch),
                onStart: () => _practiceChapter(context, ch),
                startable: state.isChapterStartable(ch.chapterId),
              ),
          ],
        );
      case ProgressStatus.error:
      case ProgressStatus.initial:
        return const SizedBox.shrink();
    }
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<(String, String)> items; // (id, name)
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border.all(color: c.border),
            borderRadius: AppRadii.cardR,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: c.bgCard,
              icon: Icon(LucideIcons.chevronDown, size: 16, color: c.textMuted),
              style: AppTypography.bodyMedium(c.textPrimary),
              items: [
                for (final it in items)
                  DropdownMenuItem(value: it.$1, child: Text(it.$2)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.hint,
    this.ctaLabel,
    this.onCta,
  });
  final IconData icon;
  final String title;
  final String hint;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: context.cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accentLight,
              borderRadius: AppRadii.cardR,
            ),
            child: Icon(icon, size: 26, color: c.accent),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.h3(c.textPrimary)),
          const SizedBox(height: 6),
          Text(hint,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(c.textMuted)),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCta,
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: Text(ctaLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Subject summary: coverage + mastery gauges, chapter-health breakdown, AI coach.
class _SubjectSummary extends StatelessWidget {
  const _SubjectSummary({required this.data});
  final SubjectProgressData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final masteryCfg = _masteryConfig(context, data.subjectMastery);
    final total = data.chapterBreakdown.values.fold<int>(0, (a, b) => a + b);
    final userId = context.read<ProfileCubit>().state.user?.id ?? '';
    return Column(
      children: [
        LayoutBuilder(builder: (context, cons) {
          final wide = cons.maxWidth > 560;
          final coverage = _GaugeCard(
            label: 'COVERAGE',
            title: 'Topics Explored',
            percent: data.subjectCoverage,
            color: c.accent,
            footer: Row(children: [
              Icon(LucideIcons.trendingUp, size: 14, color: c.accent),
              const SizedBox(width: 6),
              Text(
                  data.subjectCoverage > 50
                      ? 'Great progress!'
                      : 'Keep exploring!',
                  style: AppTypography.bodySmall(c.textMuted)),
            ]),
          );
          final mastery = _GaugeCard(
            label: 'MASTERY',
            title: 'Understanding Level',
            percent: data.subjectMastery * 100,
            color: masteryCfg.color,
            footer: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: masteryCfg.bg,
                borderRadius: AppRadii.pillR,
              ),
              child: Text(masteryCfg.label,
                  style: AppTypography.bodySmall(masteryCfg.color)),
            ),
          );
          return wide
              ? Row(children: [
                  Expanded(child: coverage),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: mastery),
                ])
              : Column(
                  children: [coverage, const SizedBox(height: AppSpacing.md), mastery]);
        }),
        const SizedBox(height: AppSpacing.md),
        // Chapter health
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(LucideIcons.bookOpen, size: 14, color: c.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text('CHAPTER HEALTH',
                        style: AppTypography.mono(c.textMuted, size: 10)),
                  ]),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accentLight,
                      borderRadius: AppRadii.pillR,
                    ),
                    child: Text('$total chapters',
                        style: AppTypography.mono(c.textMuted, size: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (total > 0)
                ClipRRect(
                  borderRadius: AppRadii.pillR,
                  child: Row(
                    children: [
                      for (final entry in _breakdownOrder)
                        if ((data.chapterBreakdown[entry.$1] ?? 0) > 0)
                          Expanded(
                            flex: data.chapterBreakdown[entry.$1]!,
                            child:
                                Container(height: 6, color: entry.$2(context)),
                          ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  for (final entry in _breakdownOrder)
                    if ((data.chapterBreakdown[entry.$1] ?? 0) > 0)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: entry.$2(context), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('${data.chapterBreakdown[entry.$1]} ${entry.$3}',
                            style: AppTypography.bodySmall(c.textMuted)),
                      ]),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (userId.isNotEmpty)
          _AiCoachCard(
            loader: () =>
                sl<ProgressRepository>().subjectInsight(userId, data.subjectId),
          ),
      ],
    );
  }

  static final List<(String, Color Function(BuildContext), String)>
      _breakdownOrder = [
    ('not_started', (c) => c.colors.border, 'Not Started'),
    ('weak', (c) => c.colors.danger, 'Weak'),
    ('needs_revision', (c) => c.colors.warning, 'Needs Revision'),
    ('good', (c) => c.colors.warning, 'Good'),
    ('strong', (c) => c.colors.accent, 'Strong'),
  ];
}

({String label, Color color, Color bg}) _masteryConfig(
    BuildContext context, double score) {
  final c = context.colors;
  if (score < 0.4)
    return (
      label: 'Needs Work',
      color: c.danger,
      bg: c.danger.withValues(alpha: 0.1)
    );
  if (score < 0.6)
    return (
      label: 'Getting There',
      color: c.warning,
      bg: c.warning.withValues(alpha: 0.1)
    );
  if (score < 0.8)
    return (
      label: 'Good Progress',
      color: c.warning,
      bg: c.warning.withValues(alpha: 0.1)
    );
  return (label: 'Excellent!', color: c.accent, bg: c.accentLight);
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.label,
    required this.title,
    required this.percent,
    required this.color,
    required this.footer,
  });
  final String label;
  final String title;
  final double percent; // 0..100
  final Color color;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
                const SizedBox(height: AppSpacing.xxs),
                Text(title,
                    style:
                        AppTypography.h4(c.textPrimary).copyWith(fontSize: 17)),
                const SizedBox(height: AppSpacing.sm),
                footer,
              ],
            ),
          ),
          _CircularGauge(percent: percent, color: color),
        ],
      ),
    );
  }
}

class _CircularGauge extends StatelessWidget {
  const _CircularGauge({required this.percent, required this.color});
  final double percent;
  final Color color;
  static const double size = 92;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              strokeWidth: 9,
              backgroundColor: c.accentLight,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text('${percent.round()}%',
              style: AppTypography.statNumber(c.textPrimary, size: 18)),
        ],
      ),
    );
  }
}

/// Starts a practice session for [chapter] using the currently-selected
/// class/subject and jumps straight into the questions, skipping the config
/// funnel. Falls back to the config funnel if the selection can't be resolved.
void _practiceChapter(BuildContext context, ChapterProgress chapter) {
  final progress = context.read<ProgressCubit>().state;
  // Non-startable chapters have no questions generated yet; starting one lands
  // the user on an error page, so block it here (the button is also disabled).
  if (!progress.isChapterStartable(chapter.chapterId)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Questions for this chapter aren\'t ready yet.')),
    );
    return;
  }
  final cls = progress.classes.where((c) => c.id == progress.selectedClassId);
  final subj =
      progress.subjects.where((s) => s.id == progress.selectedSubjectId);
  if (cls.isEmpty || subj.isEmpty) {
    context.go(RoutePaths.study);
    return;
  }
  final userId = context.read<ProfileCubit>().state.user?.id ?? '';
  context.read<SessionBloc>().add(ChapterPracticeStarted(
        userId: userId,
        returnRoute: RoutePaths.progress,
        classOption: tax.ClassOption(id: cls.first.id, name: cls.first.name),
        subject: tax.SubjectOption(
            id: subj.first.id, name: subj.first.name, classId: cls.first.id),
        chapter: tax.ChapterOption(
          id: chapter.chapterId,
          name: chapter.name,
          number: chapter.order,
          subjectId: subj.first.id,
        ),
      ));
  context.go(RoutePaths.study);
}

/// A chapter card in the list with coverage + mastery bars and a Start button.
class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.onOpen,
    required this.onStart,
    required this.startable,
  });
  final ChapterProgress chapter;
  final VoidCallback onOpen;
  final VoidCallback onStart;
  final bool startable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final masteryColor = chapter.masteryScore < 0.4
        ? c.danger
        : chapter.masteryScore < 0.8
            ? c.warning
            : c.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadii.cardR,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Chapter ${chapter.order}',
                      style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.bgRaised,
                      borderRadius: AppRadii.pillR,
                    ),
                    child: Text(
                        chapter.status.replaceAll('_', ' ').toLowerCase(),
                        style: AppTypography.mono(c.textMuted, size: 9)),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.chevronRight, size: 16, color: c.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(chapter.name,
                  style:
                      AppTypography.h4(c.textPrimary).copyWith(fontSize: 17)),
              if (chapter.totalTopics > 0) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                    '${chapter.totalTopics} topics • ${chapter.attemptedTopics} practiced',
                    style: AppTypography.bodySmall(c.textMuted)),
              ],
              const SizedBox(height: 14),
              _BarRow(
                  label: 'Coverage',
                  percent: chapter.coveragePercent,
                  color: c.accent),
              const SizedBox(height: 10),
              _BarRow(
                  label: 'Mastery',
                  percent: chapter.masteryScore * 100,
                  color: masteryColor),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: startable ? onStart : null,
                  icon: Icon(
                      startable ? LucideIcons.circlePlay : LucideIcons.lock,
                      size: 15),
                  label:
                      Text(startable ? 'Practice this chapter' : 'Coming Soon'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: c.border,
                    disabledForegroundColor: c.textMuted,
                    shape: const StadiumBorder(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow(
      {required this.label, required this.percent, required this.color});
  final String label;
  final double percent; // 0..100
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall(c.textMuted)),
            Text('${percent.round()}%',
                style: AppTypography.mono(color, size: 11)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        ClipRRect(
          borderRadius: AppRadii.pillR,
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0, 1),
            minHeight: 6,
            backgroundColor: c.bgRaised,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// Chapter detail: header, coverage bar, weak/learning summary, AI coach, topics.
class _ChapterDetail extends StatelessWidget {
  const _ChapterDetail({required this.chapter});
  final ChapterProgress chapter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cfg = _masteryConfig(context, chapter.masteryScore);
    final weak = chapter.topics.where((t) => t.state == 'WEAK').length;
    final learning = chapter.topics.where((t) => t.state == 'LEARNING').length;
    final userId = context.read<ProfileCubit>().state.user?.id ?? '';
    final startable = context
        .read<ProgressCubit>()
        .state
        .isChapterStartable(chapter.chapterId);
    final sorted = [...chapter.topics]
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.read<ProgressCubit>().closeChapter(),
          icon: Icon(LucideIcons.arrowLeft, size: 16, color: c.textMuted),
          label: Text('Back to chapters',
              style: AppTypography.bodyMedium(c.textMuted)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(chapter.name,
                        style: AppTypography.h3(c.textPrimary)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: cfg.bg, borderRadius: AppRadii.pillR),
                    child: Text(cfg.label,
                        style: AppTypography.bodySmall(cfg.color)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  '${chapter.attemptedTopics} / ${chapter.totalTopics} topics (${chapter.coveragePercent.round()}%)',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(height: AppSpacing.sm),
              _BarRow(
                  label: 'Coverage',
                  percent: chapter.coveragePercent,
                  color: c.accent),
              if (weak > 0 || learning > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  [
                    if (weak > 0) '$weak weak',
                    if (learning > 0) '$learning still learning',
                  ].join(' · '),
                  style: AppTypography.bodySmall(c.warning),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (userId.isNotEmpty)
          _AiCoachCard(
            loader: () => sl<ProgressRepository>()
                .chapterInsight(userId, chapter.chapterId),
          ),
        const SizedBox(height: AppSpacing.md),
        Text('Topics',
            style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
        const SizedBox(height: 10),
        for (final t in sorted) _TopicRow(topic: t),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                startable ? () => _practiceChapter(context, chapter) : null,
            icon: Icon(startable ? LucideIcons.circlePlay : LucideIcons.lock,
                size: 16),
            label: Text(startable ? 'Practice this chapter' : 'Coming Soon'),
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: c.border,
              disabledForegroundColor: c.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic});
  final TopicItem topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (topic.state) {
      'STRONG' => c.accent,
      'WEAK' => c.danger,
      'LEARNING' => c.warning,
      _ => c.textMuted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                  child: Text(topic.name,
                      style: AppTypography.bodyMedium(c.textPrimary))),
              if (topic.masteryScore > 0)
                Text('${(topic.masteryScore * 100).round()}%',
                    style: AppTypography.mono(color, size: 11)),
            ],
          ),
          if (topic.masteryScore > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppRadii.pillR,
              child: LinearProgressIndicator(
                value: topic.masteryScore.clamp(0, 1),
                minHeight: 5,
                backgroundColor: c.bgRaised,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Collapsible "AI Learning Coach" card that lazily loads a markdown insight.
class _AiCoachCard extends StatelessWidget {
  const _AiCoachCard({required this.loader});
  final Future<String?> Function() loader;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AiCoachCubit>(
      create: (_) => sl<AiCoachCubit>(),
      child: Builder(builder: _buildCard),
    );
  }

  Widget _buildCard(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<AiCoachCubit>();
    final state = context.watch<AiCoachCubit>().state;
    return Container(
      width: double.infinity,
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: state.loading ? null : () => cubit.toggle(loader),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: AppRadii.cardR),
                    child: const Icon(LucideIcons.sparkles,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('AI Learning Coach',
                              style: AppTypography.labelLarge(c.textPrimary)),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.accentLight,
                              borderRadius: AppRadii.pillR,
                            ),
                            child: Text('BETA',
                                style: AppTypography.mono(c.accent, size: 9)),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          state.loading
                              ? 'Analyzing your progress...'
                              : state.open
                                  ? 'Click to hide insights'
                                  : 'Get personalized study recommendations',
                          style: AppTypography.bodySmall(c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (state.loading)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(
                        state.open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 18,
                        color: c.accent),
                ],
              ),
            ),
          ),
          if (state.open && state.insight != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.bgPrimary,
                  border: Border.all(color: c.border),
                  borderRadius: AppRadii.cardR,
                ),
                child: MarkdownBody(data: state.insight!),
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(state.error!, style: AppTypography.bodySmall(c.danger)),
            ),
        ],
      ),
    );
  }
}
