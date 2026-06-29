part of '../admin_dashboard_page.dart';

enum _CurriculumMode { chapters, upload, topics }

/// Class/subject-scoped curriculum management: list & delete chapters, create a
/// chapter (Upload), or browse topics. Mirrors ChapterManagement / ChapterUpload
/// / ChapterTopicView.
class _CurriculumPanel extends StatefulWidget {
  const _CurriculumPanel({required this.mode});
  final _CurriculumMode mode;
  @override
  State<_CurriculumPanel> createState() => _CurriculumPanelState();
}

class _CurriculumPanelState extends State<_CurriculumPanel> {
  final _repo = sl<AdminRepository>();
  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _items = const [];
  final Set<String> _selected = {};
  bool _loading = false;

  bool get _isChapters => widget.mode == _CurriculumMode.chapters;

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _items = const [];
      _selected.clear();
    });
    final r = await _repo.subjects(classId);
    if (!mounted) return;
    setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _loadItems(String subjectId) async {
    setState(() {
      _subjectId = subjectId;
      _loading = true;
      _items = const [];
      _selected.clear();
    });
    final classId = _classId!;
    final r = widget.mode == _CurriculumMode.topics
        ? await _repo.topics(classId, subjectId)
        : await _repo.chapters(classId, subjectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = r.getOrElse(() => const []);
    });
  }

  Future<void> _addChapter() async {
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
    if (ok == true && _classId != null && _subjectId != null) {
      final r = await _repo.createChapter(
          _classId!, _subjectId!, nameCtl.text.trim(), int.tryParse(orderCtl.text.trim()) ?? 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.isRight() ? 'Chapter created' : 'Could not create chapter')));
        if (r.isRight()) _loadItems(_subjectId!);
      }
    }
    nameCtl.dispose();
    orderCtl.dispose();
  }

  Future<void> _deleteChapter(String id) async {
    final r = await _repo.deleteChapters(_classId!, _subjectId!, [id]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.isRight() ? 'Deleted' : 'Could not delete')));
      if (r.isRight()) _loadItems(_subjectId!);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_items.map((e) => e.id));
      }
    });
  }

  /// Bulk-deletes the checked chapters (mirrors React ChapterManagement's
  /// multi-select delete with a confirm dialog + count).
  Future<void> _bulkDelete() async {
    final n = _selected.length;
    final ok = await showConfirmDialog(context,
        title: 'Delete chapters',
        message: 'Delete $n chapter(s)? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok) return;
    final r = await _repo.deleteChapters(_classId!, _subjectId!, _selected.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.isRight() ? 'Deleted $n chapter(s)' : 'Could not delete')));
      if (r.isRight()) {
        setState(() => _selected.clear());
        _loadItems(_subjectId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final classes = context.select<AdminCubit, List<AdminRecord>>((c) => c.state.classes);
    final isTopics = widget.mode == _CurriculumMode.topics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClassSubjectSelector(
          classes: classes,
          classId: _classId,
          subjects: _subjects,
          subjectId: _subjectId,
          onClass: _loadSubjects,
          onSubject: _loadItems,
        ),
        if (widget.mode != _CurriculumMode.topics && _subjectId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _addChapter,
                icon: const Icon(Icons.add, size: 16),
                label: Text(widget.mode == _CurriculumMode.upload ? 'Create chapter' : 'Add chapter'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ),
          ),
        if (_isChapters && _subjectId != null && _items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: _selected.isEmpty
                      ? false
                      : (_selected.length == _items.length ? true : null),
                  activeColor: c.accent,
                  onChanged: (_) => _toggleSelectAll(),
                ),
                Text('Select all', style: AppTypography.bodySmall(c.textSecondary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _loadItems(_subjectId!),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _bulkDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('Delete (${_selected.length})'),
                    style: FilledButton.styleFrom(
                        backgroundColor: c.danger, foregroundColor: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        Divider(height: 1, color: c.border),
        Expanded(
          child: _subjectId == null
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: isTopics ? 'Pick a class & subject' : 'Pick a class & subject',
                  hint: 'Select above to ${isTopics ? 'browse topics' : 'manage chapters'}.',
                )
              : _loading
                  ? const SkeletonListLoader()
                  : _items.isEmpty
                      ? EmptyState(
                          icon: Icons.inbox_outlined,
                          title: isTopics ? 'No topics' : 'No chapters',
                          hint: isTopics
                              ? 'This subject has no topics yet.'
                              : 'Create one with the button above.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
                          itemBuilder: (context, i) => ListTile(
                            leading: _isChapters
                                ? Checkbox(
                                    value: _selected.contains(_items[i].id),
                                    activeColor: c.accent,
                                    onChanged: (v) => setState(() => v == true
                                        ? _selected.add(_items[i].id)
                                        : _selected.remove(_items[i].id)),
                                  )
                                : null,
                            title: Text(_items[i].name, style: AppTypography.bodyMedium(c.textPrimary)),
                            subtitle: _items[i].subtitle.isEmpty
                                ? null
                                : Text(_items[i].subtitle, style: AppTypography.bodySmall(c.textMuted)),
                            trailing: widget.mode == _CurriculumMode.upload
                                ? IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                                    onPressed: () => _deleteChapter(_items[i].id),
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

