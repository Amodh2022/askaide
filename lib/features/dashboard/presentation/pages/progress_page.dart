import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/progress_models.dart';
import '../../data/progress_repository.dart';
import '../cubit/progress_cubit.dart';

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
    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<ProfileCubit>().state.user?.id ?? '';
        if (userId.isNotEmpty) {
          await context.read<ProgressCubit>().init(userId);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROGRESS', style: AppTypography.sectionLabel(c.textMuted)),
              const SizedBox(height: 8),
              Text("How far you've come.",
                  style: AppTypography.h1(c.textPrimary).copyWith(fontSize: 30)),
              const SizedBox(height: 4),
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
                            items: [for (final c in state.classes) (c.id, c.name)],
                            onChanged: (v) => v != null ? cubit.selectClass(v) : null,
                          );
                          final subjectDd = state.subjects.isEmpty
                              ? const SizedBox.shrink()
                              : _Dropdown(
                                  label: 'Select Subject',
                                  value: state.selectedSubjectId,
                                  items: [for (final s in state.subjects) (s.id, s.name)],
                                  onChanged: (v) => v != null ? cubit.selectSubject(v) : null,
                                );
                          return wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(width: 260, child: classDd),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 260, child: subjectDd),
                                  ],
                                )
                              : Column(children: [
                                  classDd,
                                  const SizedBox(height: 12),
                                  subjectDd,
                                ]);
                        }),
                      const SizedBox(height: 24),
                      _body(context, state),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _body(BuildContext context, ProgressState state) {
    final c = context.colors;
    switch (state.status) {
      case ProgressStatus.loading:
        return const SkeletonListLoader(padding: EdgeInsets.all(24));
      case ProgressStatus.empty:
        if (state.classes.isEmpty) {
          return _EmptyCard(
            icon: LucideIcons.bookOpen,
            title: 'No Classes Configured',
            hint: 'Please configure your class and subjects first to track your progress.',
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
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Chapters', style: AppTypography.h3(c.textPrimary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accentLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${data.chapters.length}',
                      style: AppTypography.mono(c.textMuted, size: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final ch in data.chapters)
              _ChapterCard(
                chapter: ch,
                onOpen: () => context.read<ProgressCubit>().openChapter(ch),
                onStart: () => context.go(RoutePaths.study),
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
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(4),
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
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 26, color: c.accent),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.h3(c.textPrimary)),
          const SizedBox(height: 6),
          Text(hint, textAlign: TextAlign.center, style: AppTypography.bodyMedium(c.textMuted)),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCta,
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: Text(ctaLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              Text(data.subjectCoverage > 50 ? 'Great progress!' : 'Keep exploring!',
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
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(masteryCfg.label, style: AppTypography.bodySmall(masteryCfg.color)),
            ),
          );
          return wide
              ? Row(children: [
                  Expanded(child: coverage),
                  const SizedBox(width: 16),
                  Expanded(child: mastery),
                ])
              : Column(children: [coverage, const SizedBox(height: 16), mastery]);
        }),
        const SizedBox(height: 16),
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
                    const SizedBox(width: 8),
                    Text('CHAPTER HEALTH', style: AppTypography.mono(c.textMuted, size: 10)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accentLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('$total chapters', style: AppTypography.mono(c.textMuted, size: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (total > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Row(
                    children: [
                      for (final entry in _breakdownOrder)
                        if ((data.chapterBreakdown[entry.$1] ?? 0) > 0)
                          Expanded(
                            flex: data.chapterBreakdown[entry.$1]!,
                            child: Container(height: 6, color: entry.$2(context)),
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
                          decoration: BoxDecoration(color: entry.$2(context), shape: BoxShape.circle),
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
        const SizedBox(height: 16),
        if (userId.isNotEmpty)
          _AiCoachCard(
            loader: () => sl<ProgressRepository>().subjectInsight(userId, data.subjectId),
          ),
      ],
    );
  }

  static final List<(String, Color Function(BuildContext), String)> _breakdownOrder = [
    ('not_started', (c) => c.colors.border, 'Not Started'),
    ('weak', (c) => c.colors.danger, 'Weak'),
    ('needs_revision', (c) => c.colors.warning, 'Needs Revision'),
    ('good', (c) => c.colors.warning, 'Good'),
    ('strong', (c) => c.colors.accent, 'Strong'),
  ];
}

({String label, Color color, Color bg}) _masteryConfig(BuildContext context, double score) {
  final c = context.colors;
  if (score < 0.4) return (label: 'Needs Work', color: c.danger, bg: c.danger.withValues(alpha: 0.1));
  if (score < 0.6) return (label: 'Getting There', color: c.warning, bg: c.warning.withValues(alpha: 0.1));
  if (score < 0.8) return (label: 'Good Progress', color: c.warning, bg: c.warning.withValues(alpha: 0.1));
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
                const SizedBox(height: 4),
                Text(title, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 17)),
                const SizedBox(height: 12),
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
          Text('${percent.round()}%', style: AppTypography.statNumber(c.textPrimary, size: 18)),
        ],
      ),
    );
  }
}

/// A chapter card in the list with coverage + mastery bars and a Start button.
class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.onOpen, required this.onStart});
  final ChapterProgress chapter;
  final VoidCallback onOpen;
  final VoidCallback onStart;

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
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Chapter ${chapter.order}', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.bgRaised,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(chapter.status.replaceAll('_', ' ').toLowerCase(),
                        style: AppTypography.mono(c.textMuted, size: 9)),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.chevronRight, size: 16, color: c.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              Text(chapter.name, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 17)),
              if (chapter.totalTopics > 0) ...[
                const SizedBox(height: 4),
                Text('${chapter.totalTopics} topics • ${chapter.attemptedTopics} practiced',
                    style: AppTypography.bodySmall(c.textMuted)),
              ],
              const SizedBox(height: 14),
              _BarRow(label: 'Coverage', percent: chapter.coveragePercent, color: c.accent),
              const SizedBox(height: 10),
              _BarRow(
                  label: 'Mastery',
                  percent: chapter.masteryScore * 100,
                  color: masteryColor),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(LucideIcons.circlePlay, size: 15),
                  label: const Text('Practice this chapter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
  const _BarRow({required this.label, required this.percent, required this.color});
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
            Text('${percent.round()}%', style: AppTypography.mono(color, size: 11)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
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
    final sorted = [...chapter.topics]..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.read<ProgressCubit>().closeChapter(),
          icon: Icon(LucideIcons.arrowLeft, size: 16, color: c.textMuted),
          label: Text('Back to chapters', style: AppTypography.bodyMedium(c.textMuted)),
        ),
        const SizedBox(height: 8),
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
                    child: Text(chapter.name, style: AppTypography.h3(c.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: cfg.bg, borderRadius: BorderRadius.circular(99)),
                    child: Text(cfg.label, style: AppTypography.bodySmall(cfg.color)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  '${chapter.attemptedTopics} / ${chapter.totalTopics} topics (${chapter.coveragePercent.round()}%)',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(height: 12),
              _BarRow(label: 'Coverage', percent: chapter.coveragePercent, color: c.accent),
              if (weak > 0 || learning > 0) ...[
                const SizedBox(height: 12),
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
        const SizedBox(height: 16),
        if (userId.isNotEmpty)
          _AiCoachCard(
            loader: () => sl<ProgressRepository>().chapterInsight(userId, chapter.chapterId),
          ),
        const SizedBox(height: 16),
        Text('Topics', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
        const SizedBox(height: 10),
        for (final t in sorted) _TopicRow(topic: t),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(RoutePaths.study),
            icon: const Icon(LucideIcons.circlePlay, size: 16),
            label: const Text('Practice this chapter'),
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
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
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(topic.name, style: AppTypography.bodyMedium(c.textPrimary))),
              if (topic.masteryScore > 0)
                Text('${(topic.masteryScore * 100).round()}%', style: AppTypography.mono(color, size: 11)),
            ],
          ),
          if (topic.masteryScore > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
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
class _AiCoachCard extends StatefulWidget {
  const _AiCoachCard({required this.loader});
  final Future<String?> Function() loader;
  @override
  State<_AiCoachCard> createState() => _AiCoachCardState();
}

class _AiCoachCardState extends State<_AiCoachCard> {
  bool _open = false;
  bool _loading = false;
  String? _insight;
  String? _error;

  Future<void> _toggle() async {
    if (_insight != null) {
      setState(() => _open = !_open);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.loader();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null || res.isEmpty) {
        _error = 'Failed to load AI insight. Please try again.';
      } else {
        _insight = res;
        _open = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _loading ? null : _toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(4)),
                    child: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('AI Learning Coach', style: AppTypography.labelLarge(c.textPrimary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.accentLight,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('BETA', style: AppTypography.mono(c.accent, size: 9)),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          _loading
                              ? 'Analyzing your progress...'
                              : _open
                                  ? 'Click to hide insights'
                                  : 'Get personalized study recommendations',
                          style: AppTypography.bodySmall(c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 18, color: c.accent),
                ],
              ),
            ),
          ),
          if (_open && _insight != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.bgPrimary,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: MarkdownBody(data: _insight!),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(_error!, style: AppTypography.bodySmall(c.danger)),
            ),
        ],
      ),
    );
  }
}
