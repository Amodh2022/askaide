part of '../admin_dashboard_page.dart';

class _ChaptersPanel extends StatefulWidget {
  const _ChaptersPanel({super.key});
  @override
  State<_ChaptersPanel> createState() => _ChaptersPanelState();
}

class _ChaptersPanelState extends State<_ChaptersPanel> {
  final _repo = sl<AdminRepository>();
  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _chapters = const [];
  final Set<String> _selected = {};
  bool _loading = false;
  bool _formOpen = false;
  bool _creating = false;
  String? _deletingId;
  bool _bulkDeleting = false;
  String _search = '';

  final _nameCtl = TextEditingController();
  final _orderCtl = TextEditingController();
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _orderCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _chapters = const [];
      _selected.clear();
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.subjects(classId);
    if (!mounted) return;
    setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _loadChapters(String subjectId) async {
    setState(() {
      _subjectId = subjectId;
      _loading = true;
      _chapters = const [];
      _selected.clear();
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.chapters(_classId!, subjectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _chapters = r.getOrElse(() => const []);
    });
  }

  Future<void> _create() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) { _snack('Chapter name is required'); return; }
    setState(() => _creating = true);
    final r = await _repo.createChapter(
        _classId!, _subjectId!, name, int.tryParse(_orderCtl.text.trim()) ?? 0);
    if (!mounted) return;
    setState(() => _creating = false);
    _snack(r.isRight() ? 'Chapter created' : 'Could not create chapter');
    if (r.isRight()) {
      _nameCtl.clear();
      _orderCtl.clear();
      setState(() => _formOpen = false);
      _loadChapters(_subjectId!);
    }
  }

  Future<void> _delete(String id) async {
    setState(() => _deletingId = id);
    final r = await _repo.deleteChapters(_classId!, _subjectId!, [id]);
    if (!mounted) return;
    setState(() => _deletingId = null);
    _snack(r.isRight() ? 'Deleted' : 'Could not delete');
    if (r.isRight()) _loadChapters(_subjectId!);
  }

  void _toggleSelectAll(List<AdminRecord> visible) {
    setState(() {
      final visibleIds = visible.map((e) => e.id).toSet();
      if (visibleIds.every(_selected.contains)) {
        _selected.removeAll(visibleIds);
      } else {
        _selected.addAll(visibleIds);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final n = _selected.length;
    final ok = await showConfirmDialog(context,
        title: 'Delete chapters',
        message: 'Delete $n chapter(s)? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok || !mounted) return;
    setState(() => _bulkDeleting = true);
    final r = await _repo.deleteChapters(_classId!, _subjectId!, _selected.toList());
    if (!mounted) return;
    setState(() => _bulkDeleting = false);
    _snack(r.isRight() ? 'Deleted $n chapter(s)' : 'Could not delete');
    if (r.isRight()) {
      setState(() => _selected.clear());
      _loadChapters(_subjectId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final classes = context.select<AdminCubit, List<AdminRecord>>((c) => c.state.classes);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('Chapter Management',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
            ),
            if (_subjectId != null && !_formOpen)
              FilledButton.icon(
                onPressed: () => setState(() => _formOpen = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Chapter'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _selectorCard(context, c, classes),
        if (_formOpen) ...[
          const SizedBox(height: 16),
          _formCard(c),
        ],
        if (_subjectId != null) ...[
          const SizedBox(height: 16),
          _chaptersCard(c),
        ],
      ],
      ),
    );
  }

  Widget _selectorCard(BuildContext context, AskAideColors c, List<AdminRecord> classes) {
    final mobile = context.isMobile;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.sectionR,
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickerField(
                  label: 'Class',
                  hint: 'Select class…',
                  items: classes,
                  selectedId: _classId,
                  onChanged: _loadSubjects,
                ),
                const SizedBox(height: 12),
                _PickerField(
                  label: 'Subject',
                  hint: 'Select subject…',
                  items: _subjects,
                  selectedId: _subjectId,
                  onChanged: _loadChapters,
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
                    selectedId: _classId,
                    onChanged: _loadSubjects,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Subject',
                    hint: 'Select subject…',
                    items: _subjects,
                    selectedId: _subjectId,
                    onChanged: _loadChapters,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _formCard(AskAideColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.sectionR,
      ),
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
                onPressed: () {
                  setState(() => _formOpen = false);
                  _nameCtl.clear();
                  _orderCtl.clear();
                },
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHAPTER NAME *',
                          style:
                              AppTypography.mono(c.textSecondary, size: 10)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            hintText: 'e.g. Introduction to Algebra'),
                      ),
                    ],
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
                        controller: _orderCtl,
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
                onPressed: () {
                  setState(() => _formOpen = false);
                  _nameCtl.clear();
                  _orderCtl.clear();
                },
                child: Text('Cancel',
                    style: AppTypography.button(c.textSecondary)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    (_creating || _nameCtl.text.trim().isEmpty) ? null : _create,
                icon: _creating
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _chaptersCard(AskAideColors c) {
    final query = _search.trim().toLowerCase();
    final visible = query.isEmpty
        ? _chapters
        : _chapters
            .where((ch) => ch.name.toLowerCase().contains(query))
            .toList();

    final visibleIds = visible.map((e) => e.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selected.contains);
    final someVisibleSelected =
        visibleIds.any(_selected.contains) && !allVisibleSelected;

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.sectionR,
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
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: AppRadii.pillR,
                    ),
                    child: Text(
                      query.isEmpty
                          ? '${_chapters.length}'
                          : '${visible.length} of ${_chapters.length}',
                      style: AppTypography.mono(c.accent, size: 11),
                    ),
                  ),
                const Spacer(),
                if (!_loading && _chapters.isNotEmpty) ...[
                  Checkbox(
                    tristate: true,
                    value: someVisibleSelected ? null : allVisibleSelected,
                    activeColor: c.accent,
                    onChanged: (_) => _toggleSelectAll(visible),
                  ),
                  Text('All',
                      style: AppTypography.bodySmall(c.textSecondary)),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _loadChapters(_subjectId!),
                    icon: Icon(Icons.refresh,
                        size: 18, color: c.textMuted),
                    tooltip: 'Refresh',
                  ),
                ],
              ],
            ),
          ),

          // ── Bulk-action bar (only when items are selected) ───────────────
          if (_selected.isNotEmpty)
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
                  Text('${_selected.length} selected',
                      style: AppTypography.bodySmall(c.danger)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _selected.clear()),
                    icon: Icon(Icons.close, size: 14, color: c.textMuted),
                    label: Text('Clear',
                        style: AppTypography.bodySmall(c.textMuted)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8)),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: _bulkDeleting ? null : _bulkDelete,
                    icon: _bulkDeleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      _bulkDeleting
                          ? 'Deleting…'
                          : 'Delete (${_selected.length})',
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
          if (!_loading && _chapters.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search chapters…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: c.textMuted),
                          onPressed: () => setState(
                              () { _search = ''; _searchCtl.clear(); }),
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: AppRadii.componentR,
                      borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.componentR,
                      borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.componentR,
                      borderSide:
                          BorderSide(color: c.accent, width: 1.5)),
                ),
              ),
            ),

          Divider(height: 1, color: c.border),

          // ── Body ─────────────────────────────────────────────────────────
          if (_loading)
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
              final isDeleting = _deletingId == ch.id;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Checkbox(
                      value: _selected.contains(ch.id),
                      activeColor: c.accent,
                      onChanged: (v) => setState(() => v == true
                          ? _selected.add(ch.id)
                          : _selected.remove(ch.id)),
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
                            onPressed: () => _delete(ch.id),
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

