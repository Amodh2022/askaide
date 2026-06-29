part of '../admin_dashboard_page.dart';

class _TopicsPanel extends StatefulWidget {
  const _TopicsPanel({super.key});
  @override
  State<_TopicsPanel> createState() => _TopicsPanelState();
}

class _TopicsPanelState extends State<_TopicsPanel> {
  final _repo = sl<AdminRepository>();
  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _topics = const [];
  bool _loading = false;
  String _search = '';

  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _topics = const [];
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.subjects(classId);
    if (!mounted) return;
    setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _loadTopics(String subjectId) async {
    setState(() {
      _subjectId = subjectId;
      _loading = true;
      _topics = const [];
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.topics(_classId!, subjectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _topics = r.getOrElse(() => const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final classes = context.select<AdminCubit, List<AdminRecord>>((c) => c.state.classes);

    final query = _search.trim().toLowerCase();
    final visible = query.isEmpty
        ? _topics
        : _topics.where((t) => t.name.toLowerCase().contains(query)).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            if (_subjectId != null)
              IconButton(
                onPressed: () => _loadTopics(_subjectId!),
                icon: Icon(Icons.refresh, size: 20, color: c.textMuted),
                tooltip: 'Refresh',
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Class + Subject selector card ────────────────────────────────────
        _selectorCard(context, c, classes),
        const SizedBox(height: 16),

        // ── Topics card ──────────────────────────────────────────────────────
        if (_subjectId != null) _topicsCard(c, visible),
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
                  onChanged: _loadTopics,
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
                    onChanged: _loadTopics,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _topicsCard(AskAideColors c, List<AdminRecord> visible) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.sectionR,
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
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: AppRadii.pillR,
                    ),
                    child: Text(
                      _search.isEmpty
                          ? '${_topics.length}'
                          : '${visible.length} of ${_topics.length}',
                      style: AppTypography.mono(c.accent, size: 11),
                    ),
                  ),
              ],
            ),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          if (!_loading && _topics.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search topics…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: c.textMuted),
                          onPressed: () =>
                              setState(() { _search = ''; _searchCtl.clear(); }),
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

          // ── Body ────────────────────────────────────────────────────────
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonListLoader())
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.library_books_outlined,
                title: _search.isNotEmpty
                    ? 'No topics match "$_search"'
                    : 'No topics yet',
                hint: _search.isNotEmpty
                    ? 'Try a different search term.'
                    : 'Topics are generated automatically when a chapter PDF is processed.',
              ),
            )
          else
            ...List.generate(visible.length, (i) {
              final topic = visible[i];
              // Index in the full list (for stable numbering regardless of search)
              final globalIndex = _topics.indexOf(topic);
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
                        borderRadius: AppRadii.componentR,
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
