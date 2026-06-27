part of '../question_paper_pages.dart';

class _PaperHistoryView extends StatefulWidget {
  const _PaperHistoryView();
  @override
  State<_PaperHistoryView> createState() => _PaperHistoryViewState();
}

class _PaperHistoryViewState extends State<_PaperHistoryView> {
  String? _downloadingId;
  String? _deletingId;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _download(PaperSummary p) async {
    setState(() => _downloadingId = p.id);
    try {
      // Fetch the server-rendered PDF (matches the web download) and share it.
      final repo = sl<QuestionPaperRepository>();
      final r = await repo.downloadPdf(p.id);
      await r.fold(
        (f) async => _snack('Failed to download PDF: ${f.message}'),
        (bytes) => Printing.sharePdf(
          bytes: bytes,
          filename: _pdfFileName(p.title),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _confirmDelete(PaperSummary p) async {
    final cubit = context.read<PaperHistoryCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete paper?'),
        content: Text('"${p.title}" will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deletingId = p.id);
    final success = await cubit.delete(p.id);
    if (!mounted) return;
    setState(() => _deletingId = null);
    _snack(success ? 'Paper deleted' : 'Failed to delete paper');
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour12 =
        d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final mm = d.minute.toString().padLeft(2, '0');
    final amPm = d.hour < 12 ? 'AM' : 'PM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}, $hour12:$mm $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<PaperHistoryCubit, PaperHistoryState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon badge + title + count + Generate New button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.fileText,
                            size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paper History',
                                style: AppTypography.h2(c.textPrimary)
                                    .copyWith(fontSize: 22)),
                            Text(
                              state.total > 0
                                  ? '${state.total} papers generated'
                                  : 'Your generated papers',
                              style: AppTypography.bodySmall(c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.go('/question-paper'),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Generate New'),
                        style: FilledButton.styleFrom(
                            backgroundColor: c.accent,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Content
                  if (state.status == QpLoad.loading)
                    const SkeletonListLoader(padding: EdgeInsets.all(24))
                  else if (state.papers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 24),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.alertCircle,
                              size: 40, color: c.textMuted),
                          const SizedBox(height: 12),
                          Text('No papers generated yet',
                              style: AppTypography.h4(c.textPrimary)),
                          const SizedBox(height: 8),
                          Text('Create your first AI-generated question paper.',
                              style: AppTypography.bodySmall(c.textMuted),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.go('/question-paper'),
                            style: FilledButton.styleFrom(
                                backgroundColor: c.accent,
                                foregroundColor: Colors.white),
                            child: const Text('Generate First Paper'),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final p in state.papers)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.bgCard,
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + date
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelLarge(
                                            c.textPrimary),
                                      ),
                                    ),
                                    if (_formatDate(p.createdAt).isNotEmpty)
                                      Text(
                                        _formatDate(p.createdAt),
                                        style: AppTypography.mono(c.textMuted,
                                            size: 10),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Class + Subject chips
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (p.className.isNotEmpty)
                                      _HistoryChip(p.className,
                                          fg: c.accent, bg: c.accentLight),
                                    if (p.subjectName.isNotEmpty)
                                      _HistoryChip(p.subjectName,
                                          fg: const Color(0xFF3B82F6),
                                          bg: const Color(0xFFEFF6FF)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Stats
                                Text(
                                  [
                                    '${p.questionCount} Q',
                                    if (p.totalMarks > 0)
                                      '${p.totalMarks} marks',
                                    if (p.duration > 0) '${p.duration} min',
                                  ].join(' · '),
                                  style: AppTypography.bodySmall(c.textMuted),
                                ),
                                const SizedBox(height: 12),
                                // Action row: Eye + Download + Delete
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => context.go(
                                          '/question-paper/preview/${p.id}'),
                                      icon: const Icon(LucideIcons.eye,
                                          size: 14),
                                      label: const Text('Preview'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.textMuted,
                                        side: BorderSide(color: c.border),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle:
                                            AppTypography.bodySmall(c.textMuted),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _downloadingId == p.id
                                          ? null
                                          : () => _download(p),
                                      icon: _downloadingId == p.id
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 1.5))
                                          : const Icon(LucideIcons.download,
                                              size: 14),
                                      label: const Text('Download'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.success,
                                        side: BorderSide(color: c.success),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle:
                                            AppTypography.bodySmall(c.success),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _deletingId == p.id
                                          ? null
                                          : () => _confirmDelete(p),
                                      icon: _deletingId == p.id
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 1.5))
                                          : const Icon(LucideIcons.trash2,
                                              size: 14),
                                      label: const Text('Delete'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.error,
                                        side: BorderSide(color: c.error),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle:
                                            AppTypography.bodySmall(c.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        // Pagination
                        if (state.totalPages > 1) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: state.page > 1
                                    ? () => context
                                        .read<PaperHistoryCubit>()
                                        .load(page: state.page - 1)
                                    : null,
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Page ${state.page} of ${state.totalPages}',
                                style: AppTypography.mono(c.textMuted, size: 11),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: state.page < state.totalPages
                                    ? () => context
                                        .read<PaperHistoryCubit>()
                                        .load(page: state.page + 1)
                                    : null,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ],
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

/// Colored pill chip for class/subject labels on history cards.
class _HistoryChip extends StatelessWidget {
  const _HistoryChip(this.label, {required this.fg, required this.bg});
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: AppTypography.bodySmall(fg).copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
