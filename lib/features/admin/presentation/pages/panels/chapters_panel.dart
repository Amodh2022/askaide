part of '../admin_dashboard_page.dart';

class _ChaptersPanel extends StatelessWidget {
  const _ChaptersPanel();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChaptersPanelCubit>(
      create: (_) => sl<ChaptersPanelCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  void _snack(BuildContext context, String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _create(BuildContext context) async {
    final panelCubit = context.read<ChaptersPanelCubit>();
    if (!panelCubit.formKey.currentState!.validate()) return;
    final ok = await panelCubit.create();
    if (!context.mounted) return;
    _snack(context, ok ? 'Chapter created' : 'Could not create chapter');
  }

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await context.read<ChaptersPanelCubit>().delete(id);
    if (!context.mounted) return;
    _snack(context, ok ? 'Deleted' : 'Could not delete');
  }

  Future<void> _bulkDelete(BuildContext context) async {
    final panelCubit = context.read<ChaptersPanelCubit>();
    final n = panelCubit.state.selected.length;
    final ok = await showConfirmDialog(context,
        title: 'Delete chapters',
        message: 'Delete $n chapter(s)? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok || !context.mounted) return;
    final deleted = await panelCubit.bulkDelete();
    if (!context.mounted) return;
    _snack(context, deleted != null ? 'Deleted $deleted chapter(s)' : 'Could not delete');
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final classes = context.watch<AdminCubit>().state.classes;
    final panelState = context.watch<ChaptersPanelCubit>().state;
    final panelCubit = context.read<ChaptersPanelCubit>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('Chapter Management',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
            ),
            if (panelState.subjectId != null && !panelState.formOpen)
              FilledButton.icon(
                onPressed: panelCubit.openForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Chapter'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _selectorCard(context, c, classes, panelCubit, panelState),
        if (panelState.formOpen) ...[
          const SizedBox(height: 16),
          _formCard(context, c, panelCubit, panelState),
        ],
        if (panelState.subjectId != null) ...[
          const SizedBox(height: 16),
          _chaptersCard(context, c, panelCubit, panelState),
        ],
      ],
    );
  }

  Widget _selectorCard(BuildContext context, AskAideColors c, List<AdminRecord> classes,
      ChaptersPanelCubit panelCubit, ChaptersPanelState panelState) {
    final mobile = context.isMobile;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickerField(
                  label: 'Class',
                  hint: 'Select class…',
                  items: classes,
                  selectedId: panelState.classId,
                  onChanged: panelCubit.loadSubjects,
                ),
                const SizedBox(height: 12),
                _PickerField(
                  label: 'Subject',
                  hint: 'Select subject…',
                  items: panelState.subjects,
                  selectedId: panelState.subjectId,
                  onChanged: panelCubit.loadChapters,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Class',
                    hint: 'Select class…',
                    items: classes,
                    selectedId: panelState.classId,
                    onChanged: panelCubit.loadSubjects,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Subject',
                    hint: 'Select subject…',
                    items: panelState.subjects,
                    selectedId: panelState.subjectId,
                    onChanged: panelCubit.loadChapters,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _formCard(BuildContext context, AskAideColors c, ChaptersPanelCubit panelCubit,
      ChaptersPanelState panelState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: panelCubit.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create New Chapter',
                    style:
                        AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                IconButton(
                  onPressed: panelCubit.closeForm,
                  icon: Icon(Icons.close, size: 20, color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth > 500;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: wide ? (box.maxWidth - 12) * 0.72 : box.maxWidth,
                    child: AdminFormField(
                      label: 'Chapter Name *',
                      controller: panelCubit.nameController,
                      hint: 'e.g. Introduction to Algebra',
                      requiredField: true,
                      requiredMessage: 'Chapter name is required',
                      labelColor: c.textSecondary,
                      dense: false,
                      applyBodyStyle: false,
                    ),
                  ),
                  SizedBox(
                    width: wide
                        ? (box.maxWidth - 12) * 0.28 - 12
                        : box.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ORDER',
                            style:
                                AppTypography.mono(c.textSecondary, size: 10)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: panelCubit.orderController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(hintText: '1'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: panelCubit.closeForm,
                  child: Text('Cancel',
                      style: AppTypography.button(c.textSecondary)),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: panelCubit.nameController,
                  builder: (context, _) => FilledButton.icon(
                    onPressed: (panelState.creating ||
                            panelCubit.nameController.text.trim().isEmpty)
                        ? null
                        : () => _create(context),
                    icon: panelState.creating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: const Text('Create Chapter'),
                    style: FilledButton.styleFrom(
                        backgroundColor: c.accent, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chaptersCard(BuildContext context, AskAideColors c, ChaptersPanelCubit panelCubit,
      ChaptersPanelState panelState) {
    final query = panelState.search.trim().toLowerCase();
    final visible = query.isEmpty
        ? panelState.chapters
        : panelState.chapters
            .where((ch) => ch.name.toLowerCase().contains(query))
            .toList();

    final visibleIds = visible.map((e) => e.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(panelState.selected.contains);
    final someVisibleSelected =
        visibleIds.any(panelState.selected.contains) && !allVisibleSelected;

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header row ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Chapters',
                    style: AppTypography.h4(c.textPrimary)
                        .copyWith(fontSize: 16)),
                const SizedBox(width: 8),
                if (!panelState.loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      query.isEmpty
                          ? '${panelState.chapters.length}'
                          : '${visible.length} of ${panelState.chapters.length}',
                      style: AppTypography.mono(c.accent, size: 11),
                    ),
                  ),
                const Spacer(),
                if (!panelState.loading && panelState.chapters.isNotEmpty) ...[
                  Checkbox(
                    tristate: true,
                    value: someVisibleSelected ? null : allVisibleSelected,
                    activeColor: c.accent,
                    onChanged: (_) =>
                        panelCubit.toggleSelectAll(visibleIds.toList()),
                  ),
                  Text('All',
                      style: AppTypography.bodySmall(c.textSecondary)),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => panelCubit.loadChapters(panelState.subjectId!),
                    icon: Icon(Icons.refresh,
                        size: 18, color: c.textMuted),
                    tooltip: 'Refresh',
                  ),
                ],
              ],
            ),
          ),

          // ── Bulk-action bar (only when items are selected) ───────────────
          if (panelState.selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.06),
                border: Border(
                  top: BorderSide(color: c.danger.withValues(alpha: 0.2)),
                  bottom: BorderSide(color: c.danger.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined,
                      size: 16, color: c.danger),
                  const SizedBox(width: 8),
                  Text('${panelState.selected.length} selected',
                      style: AppTypography.bodySmall(c.danger)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: panelCubit.clearSelection,
                    icon: Icon(Icons.close, size: 14, color: c.textMuted),
                    label: Text('Clear',
                        style: AppTypography.bodySmall(c.textMuted)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8)),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed:
                        panelState.bulkDeleting ? null : () => _bulkDelete(context),
                    icon: panelState.bulkDeleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      panelState.bulkDeleting
                          ? 'Deleting…'
                          : 'Delete (${panelState.selected.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

          // ── Search bar ───────────────────────────────────────────────────
          if (!panelState.loading && panelState.chapters.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: panelCubit.searchController,
                onChanged: panelCubit.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search chapters…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: panelState.search.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: c.textMuted),
                          onPressed: () {
                            panelCubit.searchController.clear();
                            panelCubit.setSearch('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: c.accent, width: 1.5)),
                ),
              ),
            ),

          Divider(height: 1, color: c.border),

          // ── Body ─────────────────────────────────────────────────────────
          if (panelState.loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonListLoader())
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: query.isNotEmpty
                    ? 'No chapters match "$query"'
                    : 'No chapters yet',
                hint: query.isNotEmpty
                    ? 'Try a different search term.'
                    : 'Use "Add Chapter" above to create the first one.',
              ),
            )
          else
            ...List.generate(visible.length, (i) {
              final ch = visible[i];
              final isDeleting = panelState.deletingId == ch.id;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Checkbox(
                      value: panelState.selected.contains(ch.id),
                      activeColor: c.accent,
                      onChanged: (_) => panelCubit.toggleItem(ch.id),
                    ),
                    title: Text(ch.name,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.bodyMedium(c.textPrimary)),
                    subtitle: ch.subtitle.isNotEmpty
                        ? Text(ch.subtitle,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTypography.bodySmall(c.textMuted))
                        : null,
                    trailing: isDeleting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: c.danger),
                            onPressed: () => _delete(context, ch.id),
                            tooltip: 'Delete chapter',
                          ),
                  ),
                  if (i < visible.length - 1)
                    Divider(height: 1, color: c.borderSubtle),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topics tab — read-only browse of topics for a class + subject.
// Topics are auto-generated by AI ingestion; admin can only view them.
// ─────────────────────────────────────────────────────────────────────────────
