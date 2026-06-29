part of '../role_dashboard_pages.dart';

class _TeacherStudentsView extends StatefulWidget {
  const _TeacherStudentsView({required this.subjectId});
  final String subjectId;

  @override
  State<_TeacherStudentsView> createState() => _TeacherStudentsViewState();
}

class _TeacherStudentsViewState extends State<_TeacherStudentsView> {
  String _search = '';
  String _statusFilter = 'all';
  String _sortBy = 'mastery';
  bool _sortDesc = true;

  List<StudentRow> _filter(List<StudentRow> list) {
    var result = [...list];
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((s) =>
          s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q)).toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((s) {
        final st = s.status.toUpperCase();
        switch (_statusFilter) {
          case 'struggling': return st.contains('NEEDS') || st.contains('WEAK');
          case 'top': return st == 'STRONG';
          case 'inactive': return st == 'INACTIVE' || s.daysInactive > 3;
          default: return true;
        }
      }).toList();
    }
    result.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name': cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'coverage': cmp = a.coverage.compareTo(b.coverage);
        case 'lastActive': cmp = a.lastPracticed.compareTo(b.lastPracticed);
        default: cmp = a.mastery.compareTo(b.mastery);
      }
      return _sortDesc ? -cmp : cmp;
    });
    return result;
  }

  String _lastActive(String iso) {
    if (iso.isEmpty) return 'Never';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherStudentsCubit, TeacherStudentsState>(
      builder: (context, state) {
        final students = state.status == TLoad.loaded ? _filter(state.students) : <StudentRow>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/${widget.subjectId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Subject Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('STUDENT ROSTER', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 4),
                  Text('Students', style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  Text('${state.totalCount} students enrolled', style: AppTypography.bodySmall(c.textMuted)),
                  const SizedBox(height: 16),

                  // Filters
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: AppTypography.bodySmall(c.textPrimary),
                    cursorColor: c.accent,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.bgCard,
                      hintText: 'Search students...',
                      hintStyle: AppTypography.bodySmall(c.textMuted),
                      prefixIcon: Icon(LucideIcons.search, size: 16, color: c.textMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.accent)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownPill<String>(
                          value: _statusFilter,
                          items: const [
                            ('all', 'All Students'),
                            ('struggling', 'Struggling'),
                            ('top', 'Top Performers'),
                            ('inactive', 'Inactive'),
                          ],
                          onChanged: (v) => setState(() => _statusFilter = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DropdownPill<String>(
                          value: _sortBy,
                          items: const [
                            ('mastery', 'Sort: Mastery'),
                            ('name', 'Sort: Name'),
                            ('coverage', 'Sort: Coverage'),
                            ('lastActive', 'Sort: Last Active'),
                          ],
                          onChanged: (v) => setState(() => _sortBy = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _sortDesc = !_sortDesc),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.bgCard,
                            border: Border.all(color: c.border),
                            borderRadius: AppRadii.cardR,
                          ),
                          child: Icon(LucideIcons.arrowUpDown, size: 16, color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state.status == TLoad.loading)
                    const SkeletonListLoader()
                  else if (students.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.users, size: 32, color: c.textMuted),
                          const SizedBox(height: 8),
                          Text('No students match', style: AppTypography.bodyMedium(c.textMuted)),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: context.cardDecoration(),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: c.bgCard,
                            child: Row(
                              children: [
                                Expanded(child: Text('STUDENT', style: AppTypography.mono(c.textMuted, size: 9))),
                                SizedBox(width: 70, child: Text('STATUS', style: AppTypography.mono(c.textMuted, size: 9))),
                                SizedBox(width: 60, child: Text('CHAPTERS', style: AppTypography.mono(c.textMuted, size: 9))),
                                SizedBox(width: 55, child: Text('MASTERY', style: AppTypography.mono(c.textMuted, size: 9))),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: c.border),
                          for (int i = 0; i < students.length; i++) ...[
                            _StudentTableRow(
                              student: students[i],
                              subjectId: widget.subjectId,
                              lastActiveLabel: _lastActive(students[i].lastPracticed),
                            ),
                            if (i < students.length - 1) Divider(height: 1, color: c.border),
                          ],
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

class _StudentTableRow extends StatelessWidget {
  const _StudentTableRow({required this.student, required this.subjectId, required this.lastActiveLabel});
  final StudentRow student;
  final String subjectId;
  final String lastActiveLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = student.status.toUpperCase();
    final isTop = st == 'STRONG';
    final isStruggling = st.contains('NEEDS') || st.contains('WEAK');
    final statusColor = isTop ? c.accent : isStruggling ? c.danger : c.warning;
    final statusLabel = isTop ? 'Top' : isStruggling ? 'Struggling' : 'Active';

    return GestureDetector(
      onTap: () => context.go('/teacher/subject/$subjectId/student/${student.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name,
                            style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${student.className}${student.section.isNotEmpty ? ' — ${student.section}' : ''}',
                            style: AppTypography.bodySmall(c.textMuted), maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadii.pillR,
                ),
                child: Text(statusLabel,
                    style: AppTypography.mono(statusColor, size: 8), textAlign: TextAlign.center),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text('${student.chaptersCompleted}/${student.totalChapters}',
                  style: AppTypography.mono(c.textPrimary, size: 11)),
            ),
            SizedBox(
              width: 55,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _MasteryGauge(value: student.mastery, size: _GaugeSize.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
