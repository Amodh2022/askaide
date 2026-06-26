import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/quiz_models.dart';
import '../quiz_cubits.dart';

/// `/quizzes` — the student's available-quiz list, loaded live.
class StudentQuizListPage extends StatelessWidget {
  const StudentQuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<QuizListCubit>(
      create: (_) {
        final cubit = sl<QuizListCubit>();
        if (!isSuperAdmin) cubit.loadAvailable(page: 1, limit: 12);
        return cubit;
      },
      child: _QuizListView(isMockMode: isSuperAdmin),
    );
  }
}

class _QuizListView extends StatefulWidget {
  const _QuizListView({this.isMockMode = false});
  final bool isMockMode;
  @override
  State<_QuizListView> createState() => _QuizListViewState();
}

class _QuizListViewState extends State<_QuizListView> {
  String _query = '';
  String _statusFilter = ''; // '' | available | in_progress | completed

  // Mirror of MOCK_QUIZZES from StudentQuizList.jsx — shown to Admin/SuperAdmin.
  List<QuizSummary> get _mockQuizzes {
    final now = DateTime.now();
    return [
      QuizSummary(
        id: 'mock-1',
        title: 'Mathematics Final Review',
        description:
            'Comprehensive review of algebra and geometry concepts covered this semester.',
        totalQuestions: 20,
        totalMarks: 50,
        status: 'available',
        subjectName: 'Mathematics',
        className: '10th Grade',
        timeLimitMinutes: 60,
        deadline: now.add(const Duration(days: 2)).toIso8601String(),
        canAttempt: true,
      ),
      QuizSummary(
        id: 'mock-2',
        title: 'Physics Chapter 3: Forces',
        description:
            "Test your understanding of Newton's laws and force vectors.",
        totalQuestions: 15,
        totalMarks: 30,
        status: 'completed',
        subjectName: 'Physics',
        className: '10th Grade',
        timeLimitMinutes: 45,
        deadline: now.subtract(const Duration(days: 1)).toIso8601String(),
        bestScore: 85,
        totalAttempts: 1,
        canAttempt: false,
        isExpired: true,
        lastAttemptId: 'mock-attempt-2',
      ),
      const QuizSummary(
        id: 'mock-3',
        title: 'English Literature: Shakespeare',
        description: 'Analysis of Macbeth and varying themes throughout the play.',
        totalQuestions: 10,
        totalMarks: 20,
        status: 'in_progress',
        subjectName: 'English',
        className: '10th Grade',
        timeLimitMinutes: 30,
        bestScore: 40,
        totalAttempts: 1,
        inProgressAttemptId: 'mock-attempt-3',
        canAttempt: true,
      ),
    ];
  }

  void _loadPage(int page) {
    if (widget.isMockMode) return;
    context.read<QuizListCubit>().loadAvailable(
          page: page,
          limit: 12,
          status: _statusFilter.isEmpty ? null : _statusFilter,
        );
  }

  void _setStatusFilter(String value) {
    setState(() => _statusFilter = value);
    if (!widget.isMockMode) _loadPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return RefreshIndicator(
      onRefresh: () async {
        if (!widget.isMockMode) {
          await context.read<QuizListCubit>().loadAvailable(page: 1, limit: 12);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: PageHeader(
                        eyebrow: 'QUIZZES',
                        title: 'My',
                      emphasis: 'Quizzes',
                      subtitle:
                          'Take quizzes assigned to you and track your progress.',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(RoutePaths.quizHistory),
                    icon: Icon(LucideIcons.history, size: 16, color: c.accent),
                    label: Text('History',
                        style: AppTypography.bodyMedium(c.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              BlocBuilder<QuizListCubit, QuizListState>(
                builder: (context, state) {
                  if (!widget.isMockMode && state.status == Load.loading) {
                    return const SkeletonListLoader(
                        padding: EdgeInsets.all(24));
                  }
                  final all =
                      widget.isMockMode ? _mockQuizzes : state.available;
                  // Stats mirror StudentQuizList: available / in-progress / completed.
                  final available = all
                      .where((q) => q.status == 'available' && q.canAttempt)
                      .length;
                  final inProgress =
                      all.where((q) => q.status == 'in_progress').length;
                  final completed =
                      all.where((q) => q.bestScore != null).length;

                  // Apply status filter + search.
                  var filtered = all;
                  if (_statusFilter.isNotEmpty) {
                    filtered = filtered
                        .where((q) => q.status == _statusFilter)
                        .toList();
                  }
                  if (_query.isNotEmpty) {
                    final ql = _query.toLowerCase();
                    filtered = filtered
                        .where((q) =>
                            q.title.toLowerCase().contains(ql) ||
                            q.description.toLowerCase().contains(ql))
                        .toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats cards
                      Row(
                        children: [
                          _QuizStat(
                              icon: LucideIcons.play,
                              color: c.accent,
                              value: available,
                              label: 'AVAILABLE'),
                          const SizedBox(width: 12),
                          _QuizStat(
                              icon: LucideIcons.refreshCw,
                              color: c.warning,
                              value: inProgress,
                              label: 'IN PROGRESS'),
                          const SizedBox(width: 12),
                          _QuizStat(
                              icon: LucideIcons.circleCheck,
                              color: c.accent,
                              value: completed,
                              label: 'COMPLETED'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search + status filter
                      LayoutBuilder(builder: (context, cons) {
                        final search = TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Search quizzes...',
                            prefixIcon: Icon(LucideIcons.search,
                                size: 18, color: c.textMuted),
                            isDense: true,
                            filled: true,
                            fillColor: c.bgCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: c.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: c.border),
                            ),
                          ),
                        );
                        final filter = _StatusDropdown(
                          value: _statusFilter,
                          onChanged: _setStatusFilter,
                        );
                        if (cons.maxWidth < 520) {
                          return Column(children: [
                            search,
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: filter),
                          ]);
                        }
                        return Row(children: [
                          Expanded(child: search),
                          const SizedBox(width: 12),
                          filter,
                        ]);
                      }),
                      const SizedBox(height: 20),
                      if (filtered.isEmpty)
                        _QuizListEmpty(
                            filtered:
                                _query.isNotEmpty || _statusFilter.isNotEmpty)
                      else
                        LayoutBuilder(builder: (context, cons) {
                          final cols = cons.maxWidth >= 900
                              ? 3
                              : (cons.maxWidth >= 600 ? 2 : 1);
                          const gap = 16.0;
                          final w = (cons.maxWidth - gap * (cols - 1)) / cols;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final q in filtered)
                                SizedBox(
                                    width: cols == 1 ? cons.maxWidth : w,
                                    child: _QuizCard(quiz: q)),
                            ],
                          );
                        }),
                      if (!widget.isMockMode && state.pagination.pages > 1) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: state.pagination.page > 1
                                  ? () => _loadPage(state.pagination.page - 1)
                                  : null,
                              child: const Text('Previous'),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${state.pagination.page} / ${state.pagination.pages}',
                              style: AppTypography.bodyMedium(c.textMuted),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: state.pagination.page <
                                      state.pagination.pages
                                  ? () => _loadPage(state.pagination.page + 1)
                                  : null,
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
      ),
    );
  }
}

/// One of the three count cards atop the quiz list.
class _QuizStat extends StatelessWidget {
  const _QuizStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: context.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 8),
            Text('$value',
                style: AppTypography.statNumber(c.textPrimary, size: 22)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
          ],
        ),
      ),
    );
  }
}

/// Status filter dropdown (All / Available / In Progress / Completed).
class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: c.textMuted),
          dropdownColor: c.bgCard,
          style: AppTypography.bodyMedium(c.textPrimary),
          items: const [
            DropdownMenuItem(value: '', child: Text('All Status')),
            DropdownMenuItem(value: 'available', child: Text('Available')),
            DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
          ],
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }
}

class _QuizListEmpty extends StatelessWidget {
  const _QuizListEmpty({required this.filtered});
  final bool filtered;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
            child: Icon(LucideIcons.bookOpen, size: 28, color: c.accent),
          ),
          const SizedBox(height: 16),
          Text(
              filtered
                  ? 'No quizzes match your filters'
                  : 'Nothing assigned yet',
              textAlign: TextAlign.center,
              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'No quizzes match this view. Try adjusting your filters or come back later.'
                : "Quizzes will appear here once your teacher assigns them. When they do, you'll be the first to know!",
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// A rich quiz card mirroring the frontend StudentQuizList QuizCard: status /
/// urgency badge, description, stat row, subject + class chips, deadline banner,
/// best-score panel, and a status-dependent action footer.
class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});
  final QuizSummary quiz;

  ({Color fg, Color bg}) _statusStyle(BuildContext context) {
    final c = context.colors;
    switch (quiz.status) {
      case 'in_progress':
        return (fg: c.warning, bg: c.warningBg);
      case 'expired':
        return (fg: c.textMuted, bg: c.bgPrimary);
      default: // available | completed
        return (fg: c.accent, bg: c.accentLight);
    }
  }

  String? _urgencyLabel() {
    final d = quiz.deadlineDate;
    if (d == null || quiz.isExpired) return null;
    final diff = d.difference(DateTime.now());
    final days = diff.inDays;
    if (days <= 0) return 'Due today!';
    if (days == 1) return 'Due tomorrow';
    return null;
  }

  String _formatDeadline(DateTime d) {
    final diff = d.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    if (days > 1) return 'in $days days';
    if (days == 1) return 'tomorrow';
    if (hours > 1) return 'in $hours hours';
    if (hours == 1) return 'in 1 hour';
    return 'less than 1 hour';
  }

  /// Starts a fresh attempt. The "new" segment is a placeholder — the attempt
  /// screen calls the resume-or-create `/start` endpoint regardless.
  void _goAttempt(BuildContext context) =>
      context.go('/quiz/${quiz.id}/attempt/new');

  /// Resumes the in-progress attempt, routing to its real id so the URL
  /// reflects the attempt (mirrors the frontend's handleResume).
  void _goResume(BuildContext context) =>
      context.go('/quiz/${quiz.id}/attempt/${quiz.inProgressAttemptId}');

  void _viewResult(BuildContext context) {
    if (quiz.lastAttemptId != null) {
      context.go('/quiz/result/${quiz.lastAttemptId}');
    } else {
      context.go(RoutePaths.quizHistory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = _statusStyle(context);
    final urgency = _urgencyLabel();
    final badgeLabel = (urgency ??
            {
              'available': 'Available',
              'in_progress': 'In Progress',
              'completed': 'Completed',
              'expired': 'Expired',
            }[quiz.status] ??
            quiz.status)
        .toUpperCase();
    final badgeFg = urgency != null ? c.warning : style.fg;
    final badgeBg = urgency != null ? c.warningBg : style.bg;

    return Container(
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(quiz.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h4(c.textPrimary)
                              .copyWith(fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(99)),
                      child: Text(badgeLabel,
                          style: AppTypography.mono(badgeFg, size: 9)),
                    ),
                  ],
                ),
                if (quiz.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(quiz.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(c.textMuted)),
                ],
                const SizedBox(height: 12),
                // Stats
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _miniStat(context, LucideIcons.fileText,
                        '${quiz.totalQuestions} Qs'),
                    _miniStat(
                        context, LucideIcons.award, '${quiz.totalMarks} marks'),
                    if (quiz.timeLimitMinutes != null)
                      _miniStat(context, LucideIcons.timer,
                          '${quiz.timeLimitMinutes} min'),
                  ],
                ),
                const SizedBox(height: 12),
                // Subject + class chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(context, quiz.subjectName),
                    _chip(context, quiz.className),
                  ],
                ),
                const SizedBox(height: 12),
                // Deadline / availability banner
                if (quiz.deadlineDate != null)
                  _banner(
                    context,
                    icon: LucideIcons.calendar,
                    fg: quiz.isExpired ? c.danger : c.warning,
                    bg: (quiz.isExpired ? c.danger : c.warning)
                        .withValues(alpha: 0.08),
                    text: quiz.isExpired
                        ? 'Deadline passed'
                        : 'Due ${_formatDeadline(quiz.deadlineDate!).toLowerCase()}',
                  )
                else if (quiz.status == 'available')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.circleCheck, size: 13, color: c.accent),
                      const SizedBox(width: 6),
                      Text('Available now',
                          style: AppTypography.mono(c.accent, size: 11)),
                    ],
                  ),
                // Best score panel
                if (quiz.bestScore != null) ...[
                  const SizedBox(height: 12),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Best Score',
                                style: AppTypography.bodySmall(c.textMuted)),
                            Text('${quiz.bestScore}%',
                                style: AppTypography.mono(c.accent, size: 13)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        if (quiz.totalAttempts > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Attempts',
                                  style: AppTypography.bodySmall(c.textMuted)),
                              Text(
                                  '${quiz.totalAttempts}/${quiz.allowedAttempts}',
                                  style: AppTypography.mono(c.textPrimary,
                                      size: 11)),
                            ],
                          ),
                        ],
                        if (quiz.totalAttempts > 1) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(LucideIcons.trendingUp,
                                  size: 12, color: c.accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                    'Practiced ${quiz.totalAttempts} times — keep improving!',
                                    style: AppTypography.bodySmall(c.accent)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: c.bgPrimary,
              border: Border(top: BorderSide(color: c.border)),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: _actions(context),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final c = context.colors;
    if (quiz.status == 'in_progress') {
      return _btn(context,
          label: 'Resume Quiz',
          icon: LucideIcons.refreshCw,
          color: c.warning,
          onTap: () => _goResume(context));
    }
    if (quiz.status == 'completed' && quiz.canAttempt) {
      return Row(
        children: [
          Expanded(
            child: _btn(context,
                label: 'Results',
                icon: LucideIcons.circleCheck,
                outline: true,
                onTap: () => _viewResult(context)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _btn(context,
                label: 'Retry',
                icon: LucideIcons.play,
                color: c.accent,
                onTap: () => _goAttempt(context)),
          ),
        ],
      );
    }
    if (quiz.status == 'completed') {
      return _btn(context,
          label: 'View Results',
          icon: LucideIcons.circleCheck,
          color: c.accent,
          onTap: () => _viewResult(context));
    }
    if (quiz.canAttempt) {
      return _btn(context,
          label: 'Start Quiz',
          icon: LucideIcons.play,
          color: c.accent,
          onTap: () => _goAttempt(context));
    }
    return Center(
      child: Text(
        quiz.isExpired ? 'Quiz deadline has passed' : 'No attempts remaining',
        style: AppTypography.mono(c.textMuted, size: 11),
      ),
    );
  }

  Widget _btn(BuildContext context,
      {required String label,
      required IconData icon,
      Color? color,
      bool outline = false,
      required VoidCallback onTap}) {
    final c = context.colors;
    if (outline) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textMuted,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color ?? c.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String text) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c.textMuted),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.mono(c.textMuted, size: 11)),
      ],
    );
  }

  Widget _chip(BuildContext context, String text) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.accentLight, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: AppTypography.bodySmall(c.accent)),
    );
  }

  Widget _banner(BuildContext context,
      {required IconData icon,
      required Color fg,
      required Color bg,
      required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: AppTypography.mono(fg, size: 11))),
        ],
      ),
    );
  }
}

/// `/quiz/:quizId/attempt/:attemptId` — the timed quiz-taking screen. The
/// attempt is loaded via the resume-or-create `/start` endpoint (see [build]);
/// the URL's attemptId is informational only.
class QuizAttemptPage extends StatelessWidget {
  const QuizAttemptPage(
      {super.key, required this.quizId, required this.attemptId});
  final String quizId;
  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizAttemptCubit>(
      // The `/start` endpoint is resume-or-create: it returns a fresh attempt
      // for an available quiz, or the existing in-progress attempt (with its
      // saved answers) when one exists. This mirrors the frontend, which always
      // calls startQuizAttempt regardless of the URL's attemptId.
      create: (_) => sl<QuizAttemptCubit>()..start(quizId),
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: c.accent),
                ),
                const SizedBox(height: 16),
                Text('Loading quiz...',
                    style: AppTypography.mono(c.textMuted, size: 13)),
              ],
            ),
          );
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
                    icon: Icon(LucideIcons.arrowLeft,
                        size: 18, color: c.textMuted),
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
                          if (!state.submitting &&
                              state.submittedAttemptId == null) {
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
                    onPressed: state.submitting
                        ? null
                        : () => _confirmSubmit(context, state),
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
      BuildContext context, QuizAttemptState state) async {
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

  String _formatTime(int seconds) => '${seconds ~/ 60}m ${seconds % 60}s';

  String _improvementLabel(double pct, double prev) {
    final diff = (pct - prev).round();
    if (diff > 0) return "That's $diff% higher than your last quiz — nice improvement!";
    if (diff < 0) return "That's ${diff.abs()}% lower than your last quiz. Keep practicing!";
    return 'Same score as your last quiz — keep it up!';
  }

  Widget _scoreComparisonBadge(
      BuildContext context, double pct, double prev) {
    final diff = (pct - prev).round();
    final sign = diff > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('VS LAST QUIZ',
              style: AppTypography.mono(Colors.white70, size: 10)),
          const SizedBox(height: 4),
          Text('$sign$diff%',
              style: AppTypography.statNumber(Colors.white, size: 22)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<QuizResultCubit, QuizResultState>(
      builder: (context, state) {
        if (state.status == Load.loading) {
          return const SkeletonListLoader();
        }
        final r = state.result;
        if (r == null) {
          return Center(
              child: Text('Could not load results',
                  style: AppTypography.bodyMedium(c.danger)));
        }
        final passed = r.passed;
        final scoreColor = passed ? c.accent : c.danger;
        final incorrect =
            (r.questions.length - r.correctCount).clamp(0, r.questions.length);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + header
                  TextButton.icon(
                    onPressed: () => context.go(RoutePaths.quizzes),
                    icon: Icon(LucideIcons.arrowLeft,
                        size: 16, color: c.textMuted),
                    label: Text('Back to Quizzes',
                        style: AppTypography.bodyMedium(c.textMuted)),
                  ),
                  const SizedBox(height: 4),
                  Text('QUIZ RESULTS',
                      style: AppTypography.sectionLabel(c.textMuted)),
                  const SizedBox(height: 6),
                  Text(r.quizTitle,
                      style: AppTypography.h2(c.textPrimary)
                          .copyWith(fontSize: 26)),
                  const SizedBox(height: 20),

                  // Score card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                      passed
                                          ? LucideIcons.trophy
                                          : LucideIcons.circleAlert,
                                      size: 18,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      passed
                                          ? 'Congratulations! You Passed!'
                                          : 'Keep Trying!',
                                      style: AppTypography.bodyMedium(
                                          Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('${r.percentage.round()}%',
                                  style: AppTypography.statNumber(Colors.white,
                                      size: 52)),
                              const SizedBox(height: 4),
                              Text('${r.score} / ${r.totalMarks} marks',
                                  style: AppTypography.mono(Colors.white70,
                                      size: 13)),
                              if (r.previousBestPercentage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _improvementLabel(
                                      r.percentage, r.previousBestPercentage!),
                                  style: AppTypography.bodySmall(Colors.white70),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (r.previousBestPercentage != null)
                              _scoreComparisonBadge(
                                  context,
                                  r.percentage,
                                  r.previousBestPercentage!),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('PASSING SCORE',
                                      style: AppTypography.mono(Colors.white70,
                                          size: 10)),
                                  const SizedBox(height: 4),
                                  Text('${r.passingPercentage.round()}%',
                                      style: AppTypography.statNumber(
                                          Colors.white, size: 22)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stat grid
                  LayoutBuilder(builder: (context, cons) {
                    final cols = cons.maxWidth >= 560 ? 4 : 2;
                    const gap = 12.0;
                    final w = (cons.maxWidth - gap * (cols - 1)) / cols;
                    final stats = [
                      (
                        icon: LucideIcons.circleCheck,
                        color: c.accent,
                        label: 'CORRECT',
                        value: '${r.correctCount}'
                      ),
                      (
                        icon: LucideIcons.circleX,
                        color: c.danger,
                        label: 'INCORRECT',
                        value: '$incorrect'
                      ),
                      (
                        icon: LucideIcons.fileText,
                        color: c.textMuted,
                        label: 'QUESTIONS',
                        value: '${r.questions.length}'
                      ),
                      (
                        icon: LucideIcons.clock,
                        color: c.textMuted,
                        label: 'TIME SPENT',
                        value: _formatTime(r.timeSpent)
                      ),
                    ];
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final s in stats)
                          SizedBox(
                            width: w,
                            child: _ResultStat(
                                icon: s.icon,
                                color: s.color,
                                value: s.value,
                                label: s.label),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),

                  // Question review
                  if (r.showAnswers && r.questions.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              border:
                                  Border(bottom: BorderSide(color: c.border)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.bookOpen,
                                    size: 18, color: c.accent),
                                const SizedBox(width: 8),
                                Text('Question Review',
                                    style: AppTypography.h4(c.textPrimary)
                                        .copyWith(fontSize: 16)),
                              ],
                            ),
                          ),
                          for (var i = 0; i < r.questions.length; i++)
                            _ReviewTile(
                              index: i,
                              q: r.questions[i],
                              isLast: i == r.questions.length - 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go(RoutePaths.quizzes),
                          icon: const Icon(LucideIcons.bookOpen, size: 16),
                          label: const Text('More Quizzes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.textPrimary,
                            side: BorderSide(color: c.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        if (r.canRetry && r.quizId.isNotEmpty)
                          FilledButton.icon(
                            onPressed: () =>
                                context.go('/quiz/${r.quizId}/attempt/new'),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Try Again'),
                            style: FilledButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                      ],
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

/// A collapsible reviewed-question row in the result screen.
class _ReviewTile extends StatefulWidget {
  const _ReviewTile(
      {required this.index, required this.q, this.isLast = false});
  final int index;
  final QuizReviewQuestion q;
  final bool isLast;
  @override
  State<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<_ReviewTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = widget.q;
    final correct = q.isCorrect;
    return Container(
      decoration: BoxDecoration(
        border:
            widget.isLast ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: correct
                          ? c.accentLight
                          : c.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${widget.index + 1}',
                        style: AppTypography.mono(correct ? c.accent : c.danger,
                            size: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.text,
                            style: AppTypography.bodyMedium(c.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                                correct
                                    ? LucideIcons.circleCheck
                                    : LucideIcons.circleX,
                                size: 13,
                                color: correct ? c.accent : c.danger),
                            const SizedBox(width: 4),
                            Text(correct ? 'Correct' : 'Incorrect',
                                style: AppTypography.bodySmall(
                                    correct ? c.accent : c.danger)),
                            const SizedBox(width: 10),
                            Text('${q.marksObtained}/${q.marks} marks',
                                style:
                                    AppTypography.mono(c.textMuted, size: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                      _expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: c.textMuted),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _answerBox(context,
                      label: 'YOUR ANSWER',
                      text:
                          q.userAnswer.isEmpty ? 'Not answered' : q.userAnswer,
                      fg: correct ? c.accent : c.danger,
                      bg: c.bgPrimary,
                      border: c.border),
                  if (!correct && q.correctAnswer.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _answerBox(context,
                        label: 'CORRECT ANSWER',
                        text: q.correctAnswer,
                        fg: c.accent,
                        bg: c.accentLight,
                        border: c.accent),
                  ],
                  if (q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _answerBox(context,
                        label: 'EXPLANATION',
                        text: q.explanation,
                        fg: c.textPrimary,
                        labelColor: c.textMuted,
                        bg: c.bgPrimary,
                        border: c.border),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _answerBox(BuildContext context,
      {required String label,
      required String text,
      required Color fg,
      required Color bg,
      required Color border,
      Color? labelColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.mono(labelColor ?? fg, size: 10)),
          const SizedBox(height: 4),
          Text(text,
              style: AppTypography.bodySmall(fg)
                  .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.statNumber(c.textPrimary, size: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
        ],
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
      create: (_) => sl<QuizListCubit>()..loadHistory(page: 1, limit: 10),
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

  void _loadPage(int page) {
    context.read<QuizListCubit>().loadHistory(page: page, limit: 10);
  }

  String _fmtDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final amPm = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year}, $hour12:$mm $amPm';
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
                label: Text('Back to Quizzes',
                    style: AppTypography.bodyMedium(c.textMuted)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.history, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quiz History',
                    style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 22),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'View all your past quiz attempts and results',
                style: AppTypography.bodyMedium(c.textMuted),
              ),
              const SizedBox(height: 20),
              // Search
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by quiz title...',
                  prefixIcon:
                      Icon(LucideIcons.search, size: 18, color: c.textMuted),
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
                    return const SkeletonListLoader(
                        padding: EdgeInsets.all(24));
                  }
                  final filtered = state.history
                      .where((h) => h.quizTitle
                          .toLowerCase()
                          .contains(_query.toLowerCase()))
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
                  return Column(
                    children: [
                      for (final h in filtered)
                        _HistoryCard(
                          item: h,
                          date: _fmtDate(h.submittedAt),
                          time: _fmtTime(h.timeSpent),
                        ),
                      if (state.pagination.pages > 1) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: state.pagination.page > 1
                                  ? () => _loadPage(state.pagination.page - 1)
                                  : null,
                              child: const Text('Previous'),
                            ),
                            const SizedBox(width: 12),
                            Text(
                                'Page ${state.pagination.page} of ${state.pagination.pages}',
                                style: AppTypography.bodyMedium(c.textMuted)),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: state.pagination.page <
                                      state.pagination.pages
                                  ? () => _loadPage(state.pagination.page + 1)
                                  : null,
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
  const _HistoryCard(
      {required this.item, required this.date, required this.time});
  final QuizHistoryItem item;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final passed = item.isPassed;
    // Match frontend's emerald-100/rose-100 icon bg and emerald-600/rose-600 text.
    const emeraldBg = Color(0xFFD1FAE5);
    const emeraldFg = Color(0xFF059669);
    const roseBg = Color(0xFFFFE4E6);
    const roseFg = Color(0xFFE11D48);
    final iconBg = passed ? emeraldBg : roseBg;
    final scoreFg = passed ? emeraldFg : roseFg;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/quiz/result/${item.attemptId}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(passed ? LucideIcons.trophy : LucideIcons.circleX,
                    size: 24, color: scoreFg),
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
                          Icon(LucideIcons.calendar,
                              size: 13, color: c.textMuted),
                          const SizedBox(width: 4),
                          Text(date,
                              style: AppTypography.bodySmall(c.textMuted)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.clock, size: 13, color: c.textMuted),
                          const SizedBox(width: 4),
                          Text(time,
                              style: AppTypography.bodySmall(c.textMuted)),
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
                      style: AppTypography.statNumber(scoreFg, size: 22)),
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
