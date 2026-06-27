part of '../admin_dashboard_page.dart';

class _SchoolsPanel extends StatefulWidget {
  const _SchoolsPanel();
  @override
  State<_SchoolsPanel> createState() => _SchoolsPanelState();
}

class _SchoolsPanelState extends State<_SchoolsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _address = TextEditingController();
  final _board = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();

  bool _isCreating = false;
  AdminSchool? _editing;
  bool _saving = false;
  final Set<String> _deletingIds = {};

  bool get _formOpen => _isCreating || _editing != null;

  List<TextEditingController> get _all =>
      [_name, _code, _address, _board, _phone, _email, _website];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetFields() {
    for (final c in _all) {
      c.clear();
    }
  }

  void _startCreate() => setState(() {
        _editing = null;
        _isCreating = true;
        _resetFields();
      });

  void _startEdit(AdminSchool s) => setState(() {
        _editing = s;
        _isCreating = false;
        _resetFields();
        _name.text = s.name;
        _code.text = s.code;
      });

  void _cancel() => setState(() {
        _editing = null;
        _isCreating = false;
        _resetFields();
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final cubit = context.read<AdminCubit>();
    final editing = _editing;
    final bool ok;
    if (editing != null) {
      ok = await cubit.updateSchool(editing.id, {
        'schoolName': _name.text.trim(),
        'schoolCode': _code.text.trim(),
      });
    } else {
      ok = await cubit.createSchool({
        'schoolName': _name.text.trim(),
        'schoolCode': _code.text.trim(),
        'schoolAddress': _address.text.trim(),
        'schoolBoard': _board.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'schoolPhone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'schoolEmail': _email.text.trim(),
        if (_website.text.trim().isNotEmpty) 'schoolWebsite': _website.text.trim(),
      });
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (editing != null ? 'School updated successfully' : 'School created successfully')
            : 'Operation failed')));
    if (ok) _cancel();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                child: Text('School Management',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22))),
            if (!_formOpen)
              FilledButton.icon(
                onPressed: _startCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add School'),
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
          ],
        ),
        if (_formOpen) ...[
          const SizedBox(height: 16),
          _formCard(c),
        ],
        const SizedBox(height: 16),
        if (state.status == ALoad.loading && state.schools.isEmpty)
          const SkeletonListLoader()
        else
          _grid(c, state.schools),
      ],
    );
  }

  Widget _formCard(AskAideColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_editing != null ? 'Edit School' : 'Create New School',
                    style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                IconButton(onPressed: _cancel, icon: Icon(Icons.close, size: 20, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth > 520 ? (box.maxWidth - 12) / 2 : box.maxWidth;
              final fields = <Widget>[
                _field(c, 'School Name *', _name, hint: 'e.g. Greenwood High', requiredMsg: 'School Name is required'),
                _field(c, 'School Code *', _code, hint: 'e.g. GW001', requiredMsg: 'School Code is required'),
                if (_editing == null) ...[
                  _field(c, 'Address *', _address, requiredMsg: 'Address is required'),
                  _field(c, 'Board *', _board, hint: 'e.g. CBSE', requiredMsg: 'Board is required'),
                  _field(c, 'Phone', _phone),
                  _field(c, 'Email', _email, email: true),
                  _field(c, 'Website', _website),
                ],
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final f in fields) SizedBox(width: w, child: f)],
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _cancel, child: Text('Cancel', style: AppTypography.button(c.textSecondary))),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 18),
                  label: Text(_editing != null ? 'Update School' : 'Create School'),
                  style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(AskAideColors c, String label, TextEditingController ctl,
      {String? hint, String? requiredMsg, bool email = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textSecondary, size: 10)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctl,
          keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(hintText: hint),
          validator: (v) {
            final t = (v ?? '').trim();
            if (requiredMsg != null && t.isEmpty) return requiredMsg;
            if (email && t.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(AdminSchool s) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete school',
        message: 'Delete "${s.name}"? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok || !mounted) return;
    setState(() => _deletingIds.add(s.id));
    final success = await context.read<AdminCubit>().deleteSchool(s.id);
    if (!mounted) return;
    setState(() => _deletingIds.remove(s.id));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'School deleted' : 'Could not delete school')));
  }

  Widget _grid(AskAideColors c, List<AdminSchool> schools) {
    if (schools.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: EmptyState(
          icon: Icons.school_outlined,
          title: 'No schools',
          hint: 'Add one with the button above.',
        ),
      );
    }
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth > 900 ? 3 : (box.maxWidth > 600 ? 2 : 1);
      final w = (box.maxWidth - 16 * (cols - 1)) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final s in schools)
            SizedBox(width: cols == 1 ? box.maxWidth : w, child: _card(c, s)),
        ],
      );
    });
  }

  Widget _card(AskAideColors c, AdminSchool s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text('Code: ${s.code}', style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _startEdit(s),
                icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
              ),
              IconButton(
                onPressed: _deletingIds.contains(s.id) ? null : () => _confirmDelete(s),
                icon: _deletingIds.contains(s.id)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.delete_outline, size: 18, color: c.danger),
              ),
            ],
          ),
          if (s.address.isNotEmpty || s.board.isNotEmpty || s.phone.isNotEmpty ||
              s.email.isNotEmpty || s.website.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: c.border),
            const SizedBox(height: 8),
            if (s.address.isNotEmpty) _detail(c, Icons.location_on_outlined, s.address),
            if (s.board.isNotEmpty) _detail(c, Icons.school_outlined, s.board),
            if (s.phone.isNotEmpty) _detail(c, Icons.phone_outlined, s.phone),
            if (s.email.isNotEmpty) _detail(c, Icons.email_outlined, s.email),
            if (s.website.isNotEmpty) _detail(c, Icons.language_outlined, s.website),
          ],
        ],
      ),
    );
  }

  Widget _detail(AskAideColors c, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(c.textMuted)),
            ),
          ],
        ),
      );
}

/// Class-scoped section management: list (strength + active badge), single &
/// bulk create, edit (max strength + active), delete with confirm. Mirrors
/// React SectionManagement.
