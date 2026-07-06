part of '../admin_dashboard_page.dart';

enum _CurriculumMode { chapters, upload, topics }

/// Class/subject-scoped curriculum management: list & delete chapters, create a
/// chapter (Upload), or browse topics. Mirrors ChapterManagement / ChapterUpload
/// / ChapterTopicView.
class _CurriculumPanel extends StatelessWidget {
  const _CurriculumPanel({required this.mode});
  final _CurriculumMode mode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CurriculumPanelCubit>(
      create: (_) => sl<CurriculumPanelCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Future<void> _addChapter(BuildContext context) async {
    final panelCubit = context.read<CurriculumPanelCubit>();
    final nameCtl = TextEditingController();
    final orderCtl = TextEditingController();
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: c.bgCard,
        title: Text('Add chapter', style: AppTypography.h4(c.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Chapter name')),
          const SizedBox(height: 10),
          TextField(
              controller: orderCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Order')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true) {
      final success = await panelCubit.addChapter(
          nameCtl.text.trim(), int.tryParse(orderCtl.text.trim()) ?? 0);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(success ? 'Chapter created' : 'Could not create chapter')));
      }
    }
    nameCtl.dispose();
    orderCtl.dispose();
  }

  Future<void> _deleteChapter(BuildContext context, String id) async {
    final success = await context.read<CurriculumPanelCubit>().deleteChapter(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Deleted' : 'Could not delete')));
  }

  /// Bulk-deletes the checked chapters (mirrors React ChapterManagement's
  /// multi-select delete with a confirm dialog + count).
  Future<void> _bulkDelete(BuildContext context) async {
    final panelCubit = context.read<CurriculumPanelCubit>();
    final n = panelCubit.state.selected.length;
    final ok = await showConfirmDialog(context,
        title: 'Delete chapters',
        message: 'Delete $n chapter(s)? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok) return;
    final deleted = await panelCubit.bulkDelete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(deleted != null ? 'Deleted $deleted chapter(s)' : 'Could not delete')));
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final classes = context.watch<AdminCubit>().state.classes;
    final panelState = context.watch<CurriculumPanelCubit>().state;
    final panelCubit = context.read<CurriculumPanelCubit>();
    final isTopics = mode == _CurriculumMode.topics;
    final isChapters = mode == _CurriculumMode.chapters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClassSubjectSelector(
          classes: classes,
          classId: panelState.classId,
          subjects: panelState.subjects,
          subjectId: panelState.subjectId,
          onClass: panelCubit.loadSubjects,
          onSubject: (subjectId) => panelCubit.loadItems(subjectId, topics: isTopics),
        ),
        if (mode != _CurriculumMode.topics && panelState.subjectId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _addChapter(context),
                icon: const Icon(Icons.add, size: 16),
                label: Text(mode == _CurriculumMode.upload ? 'Create chapter' : 'Add chapter'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ),
          ),
        if (isChapters && panelState.subjectId != null && panelState.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: panelState.selected.isEmpty
                      ? false
                      : (panelState.selected.length == panelState.items.length ? true : null),
                  activeColor: c.accent,
                  onChanged: (_) => panelCubit.toggleSelectAll(),
                ),
                Text('Select all', style: AppTypography.bodySmall(c.textSecondary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => panelCubit.loadItems(panelState.subjectId!, topics: isTopics),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
                if (panelState.selected.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _bulkDelete(context),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('Delete (${panelState.selected.length})'),
                    style: FilledButton.styleFrom(
                        backgroundColor: c.danger, foregroundColor: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        Divider(height: 1, color: c.border),
        Expanded(
          child: panelState.subjectId == null
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: isTopics ? 'Pick a class & subject' : 'Pick a class & subject',
                  hint: 'Select above to ${isTopics ? 'browse topics' : 'manage chapters'}.',
                )
              : panelState.loading
                  ? const SkeletonListLoader()
                  : panelState.items.isEmpty
                      ? EmptyState(
                          icon: Icons.inbox_outlined,
                          title: isTopics ? 'No topics' : 'No chapters',
                          hint: isTopics
                              ? 'This subject has no topics yet.'
                              : 'Create one with the button above.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: panelState.items.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
                          itemBuilder: (context, i) => ListTile(
                            leading: isChapters
                                ? Checkbox(
                                    value: panelState.selected.contains(panelState.items[i].id),
                                    activeColor: c.accent,
                                    onChanged: (_) => panelCubit.toggleItem(panelState.items[i].id),
                                  )
                                : null,
                            title: Text(panelState.items[i].name,
                                style: AppTypography.bodyMedium(c.textPrimary)),
                            subtitle: panelState.items[i].subtitle.isEmpty
                                ? null
                                : Text(panelState.items[i].subtitle,
                                    style: AppTypography.bodySmall(c.textMuted)),
                            trailing: mode == _CurriculumMode.upload
                                ? IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                                    onPressed: () => _deleteChapter(context, panelState.items[i].id),
                                  )
                                : null,
                          ),
                        ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapters tab — card-based management matching Schools / Teachers quality.
// ─────────────────────────────────────────────────────────────────────────────

