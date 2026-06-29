part of '../quiz_pages.dart';

/// Shimmer skeleton matching the quiz list layout: stat cards + search + card grid.
class _QuizListSkeleton extends StatelessWidget {
  const _QuizListSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards row
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _ > 0 ? 12 : 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: AppRadii.cardR,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: c.bgRaised, borderRadius: AppRadii.cardR),
                        ),
                        const SizedBox(height: 8),
                        const SkeletonBox(width: 40, height: 22),
                        const SizedBox(height: 4),
                        const SkeletonBox(width: 60, height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Search + filter bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.bgCard,
                    border: Border.all(color: c.border),
                    borderRadius: AppRadii.cardR,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 140,
                height: 40,
                decoration: BoxDecoration(
                  color: c.bgCard,
                  border: Border.all(color: c.border),
                  borderRadius: AppRadii.cardR,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Quiz card grid (2 columns)
          LayoutBuilder(
            builder: (context, cons) {
              final cols = cons.maxWidth >= 600 ? 2 : 1;
              const gap = 16.0;
              final w = (cons.maxWidth - gap * (cols - 1)) / cols;
              final items = List.generate(4, (_) => _QuizCardSkeleton());
              final rows = <List<Widget>>[];
              for (var i = 0; i < items.length; i += cols) {
                rows.add(items.sublist(i, (i + cols).clamp(0, items.length)));
              }
              return Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: gap),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var j = 0; j < rows[i].length; j++) ...[
                            if (j > 0) const SizedBox(width: gap),
                            SizedBox(width: cols == 1 ? cons.maxWidth : w, child: rows[i][j]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A quiz card skeleton matching the [_QuizCard] layout.
class _QuizCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: SkeletonBox(height: 16)),
                    const SizedBox(width: 8),
                    Container(
                      width: 70,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c.bgRaised,
                        borderRadius: AppRadii.pillR,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SkeletonBox(width: double.infinity, height: 12),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Row(
                        children: [
                          SkeletonBox(width: 14, height: 14),
                          SizedBox(width: 4),
                          SkeletonBox(width: 50, height: 11),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 24,
                      width: 80,
                      decoration: BoxDecoration(
                        color: c.bgRaised,
                        borderRadius: AppRadii.cardR,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      width: 70,
                      decoration: BoxDecoration(
                        color: c.bgRaised,
                        borderRadius: AppRadii.cardR,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: c.bgPrimary,
              border: Border(top: BorderSide(color: c.border)),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
          ),
        ],
      ),
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

  // Cached source list (updated by BlocConsumer listener).
  List<QuizSummary> _sourceQuizzes = const [];
  // Pre-filtered results — recomputed only when source, query, or filter changes.
  List<QuizSummary> _filtered = const [];
  int _availableCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isMockMode) {
      _sourceQuizzes = _mockQuizzes;
      _applyFilters();
    }
  }

  void _applyFilters() {
    final all = _sourceQuizzes;
    _availableCount = all.where((q) => q.status == 'available' && q.canAttempt).length;
    _inProgressCount = all.where((q) => q.status == 'in_progress').length;
    _completedCount = all.where((q) => q.bestScore != null).length;
    var f = all;
    if (_statusFilter.isNotEmpty) {
      f = f.where((q) => q.status == _statusFilter).toList();
    }
    if (_query.isNotEmpty) {
      final ql = _query.toLowerCase();
      f = f.where((q) =>
          q.title.toLowerCase().contains(ql) ||
          q.description.toLowerCase().contains(ql)).toList();
    }
    _filtered = f;
  }

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
    setState(() {
      _statusFilter = value;
      _applyFilters();
    });
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
              BlocConsumer<QuizListCubit, QuizListState>(
                listenWhen: (p, n) => p.available != n.available || p.status != n.status,
                listener: (ctx, state) {
                  if (!widget.isMockMode) {
                    setState(() {
                      _sourceQuizzes = state.available;
                      _applyFilters();
                    });
                  }
                },
                buildWhen: (p, n) => p.status != n.status || p.pagination != n.pagination,
                builder: (context, state) {
                  if (!widget.isMockMode && state.status == Load.loading) {
                    return const _QuizListSkeleton();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats cards
                      Row(
                        children: [
                          StatCard(
                              icon: LucideIcons.play,
                              color: c.accent,
                              value: '$_availableCount',
                              label: 'AVAILABLE'),
                          const SizedBox(width: 12),
                          StatCard(
                              icon: LucideIcons.refreshCw,
                              color: c.warning,
                              value: '$_inProgressCount',
                              label: 'IN PROGRESS'),
                          const SizedBox(width: 12),
                          StatCard(
                              icon: LucideIcons.circleCheck,
                              color: c.accent,
                              value: '$_completedCount',
                              label: 'COMPLETED'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search + status filter
                      LayoutBuilder(builder: (context, cons) {
                        final search = TextField(
                          onChanged: (v) => setState(() { _query = v; _applyFilters(); }),
                          decoration: InputDecoration(
                            hintText: 'Search quizzes...',
                            prefixIcon: Icon(LucideIcons.search,
                                size: 18, color: c.textMuted),
                            isDense: true,
                            filled: true,
                            fillColor: c.bgCard,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.cardR,
                              borderSide: BorderSide(color: c.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadii.cardR,
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
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            icon: Icons.book_outlined,
                            title: _query.isNotEmpty || _statusFilter.isNotEmpty
                                ? 'No quizzes match your filters'
                                : 'Nothing assigned yet',
                            hint: _query.isNotEmpty || _statusFilter.isNotEmpty
                                ? 'Try adjusting your filters or come back later.'
                                : 'Quizzes will appear here once your teacher assigns them.',
                          ),
                        )
                      else
                        LayoutBuilder(builder: (context, cons) {
                          final cols = cons.maxWidth >= 900
                              ? 3
                              : (cons.maxWidth >= 600 ? 2 : 1);
                          const gap = 16.0;
                          final w = (cons.maxWidth - gap * (cols - 1)) / cols;
                          final rows = <List<QuizSummary>>[];
                          for (var i = 0; i < _filtered.length; i += cols) {
                            rows.add(_filtered.sublist(i, (i + cols).clamp(0, _filtered.length)));
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < rows.length; i++) ...[
                                if (i > 0) const SizedBox(height: gap),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (var j = 0; j < rows[i].length; j++) ...[
                                        if (j > 0) const SizedBox(width: gap),
                                        SizedBox(
                                          width: cols == 1 ? cons.maxWidth : w,
                                          child: _QuizCard(quiz: rows[i][j]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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
        borderRadius: AppRadii.cardR,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          borderRadius: AppRadii.pillR),
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
                      borderRadius: AppRadii.cardR,
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
          shape: RoundedRectangleBorder(borderRadius: AppRadii.cardR),
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
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardR),
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
          color: c.accentLight, borderRadius: AppRadii.cardR),
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
          BoxDecoration(color: bg, borderRadius: AppRadii.cardR),
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
