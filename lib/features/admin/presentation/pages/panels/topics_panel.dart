part of '../admin_dashboard_page.dart';

class _TopicsPanel extends StatelessWidget {
  const _TopicsPanel();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TopicsPanelCubit>(
      create: (_) => sl<TopicsPanelCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final classes = context.watch<AdminCubit>().state.classes;
    final panelState = context.watch<TopicsPanelCubit>().state;
    final panelCubit = context.read<TopicsPanelCubit>();

    final query = panelState.search.trim().toLowerCase();
    final visible = query.isEmpty
        ? panelState.topics
        : panelState.topics.where((t) => t.name.toLowerCase().contains(query)).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('Topic Browser',
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
            ),
            if (panelState.subjectId != null)
              IconButton(
                onPressed: () => panelCubit.loadTopics(panelState.subjectId!),
                icon: Icon(Icons.refresh, size: 20, color: c.textMuted),
                tooltip: 'Refresh',
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Class + Subject selector card ────────────────────────────────────
        _selectorCard(context, c, classes, panelCubit, panelState),
        const SizedBox(height: 16),

        // ── Topics card ──────────────────────────────────────────────────────
        if (panelState.subjectId != null) _topicsCard(c, panelCubit, panelState, visible),
      ],
    );
  }

  Widget _selectorCard(BuildContext context, AskAideColors c, List<AdminRecord> classes,
      TopicsPanelCubit panelCubit, TopicsPanelState panelState) {
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
                  onChanged: panelCubit.loadTopics,
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
                    onChanged: panelCubit.loadTopics,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _topicsCard(AskAideColors c, TopicsPanelCubit panelCubit, TopicsPanelState panelState,
      List<AdminRecord> visible) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Topics',
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
                      panelState.search.isEmpty
                          ? '${panelState.topics.length}'
                          : '${visible.length} of ${panelState.topics.length}',
                      style: AppTypography.mono(c.accent, size: 11),
                    ),
                  ),
              ],
            ),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          if (!panelState.loading && panelState.topics.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: panelCubit.searchController,
                onChanged: panelCubit.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search topics…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: panelState.search.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: c.textMuted),
                          onPressed: panelCubit.clearSearch,
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

          // ── Body ────────────────────────────────────────────────────────
          if (panelState.loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonListLoader())
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.library_books_outlined,
                title: panelState.search.isNotEmpty
                    ? 'No topics match "${panelState.search}"'
                    : 'No topics yet',
                hint: panelState.search.isNotEmpty
                    ? 'Try a different search term.'
                    : 'Topics are generated automatically when a chapter PDF is processed.',
              ),
            )
          else
            ...List.generate(visible.length, (i) {
              final topic = visible[i];
              // Index in the full list (for stable numbering regardless of search)
              final globalIndex = panelState.topics.indexOf(topic);
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${globalIndex + 1}',
                        style: AppTypography.mono(c.accent, size: 11),
                      ),
                    ),
                    title: Text(topic.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(c.textPrimary)),
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
/// Teachers tab — faithful port of React `TeacherManagement`: a school picker,
/// a multi-row "Add New Teachers" form (wand auto-generates email + password,
/// add/remove rows, validation), and a teachers table with inline edit + delete.
/// Responsive: the form rows and the list collapse to stacked cards on mobile.
