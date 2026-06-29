part of '../quiz_pages.dart';

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
                      borderRadius: AppRadii.sectionR,
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
                    borderRadius: AppRadii.componentR,
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.componentR,
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
        borderRadius: AppRadii.sectionR,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border.all(color: c.border),
            borderRadius: AppRadii.sectionR,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadii.sectionR,
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
