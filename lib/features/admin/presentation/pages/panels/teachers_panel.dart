part of '../admin_dashboard_page.dart';

class _TeachersPanel extends StatefulWidget {
  const _TeachersPanel();
  @override
  State<_TeachersPanel> createState() => _TeachersPanelState();
}

class _TeachersPanelState extends State<_TeachersPanel> {
  final _formKey = GlobalKey<FormState>();
  List<_PersonRow> _rows = [_PersonRow()];
  bool _creating = false;

  String? _editingId;
  final _editName = TextEditingController();
  final _editEmail = TextEditingController();
  bool _editSaving = false;
  String? _deletingId;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _editName.dispose();
    _editEmail.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _genPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    var x = DateTime.now().microsecondsSinceEpoch;
    final b = StringBuffer();
    for (var i = 0; i < 8; i++) {
      x = x * 1103515245 + 12345;
      b.write(chars[(x.abs() ~/ 65536) % chars.length]);
    }
    return '${b}Aa1!';
  }

  void _generate(int i) {
    final name = _rows[i].name.text.trim();
    if (name.isEmpty) {
      _snack('Please enter a name first');
      return;
    }
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final rand = DateTime.now().microsecondsSinceEpoch % 1000;
    setState(() {
      _rows[i].email.text = '$clean.$rand@school.com';
      _rows[i].password.text = _genPassword();
    });
    _snack('Credentials generated!');
  }

  Future<void> _submit() async {
    final schoolId = context.read<AdminCubit>().state.selectedSchoolId;
    if (schoolId == null) {
      _snack('Please select a school first');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    final payload = [
      for (final r in _rows)
        {
          'name': r.name.text.trim(),
          'email': r.email.text.trim(),
          'password': r.password.text.trim(),
          if (r.phone.text.trim().isNotEmpty) 'phone': r.phone.text.trim(),
        }
    ];
    final n = payload.length;
    final ok = await context.read<AdminCubit>().createTeachers(payload);
    if (!mounted) return;
    setState(() => _creating = false);
    _snack(ok ? 'Successfully created $n teacher${n != 1 ? 's' : ''}' : 'Failed to create teachers');
    if (ok) {
      setState(() {
        for (final r in _rows) {
          r.dispose();
        }
        _rows = [_PersonRow()];
      });
    }
  }

  void _openEdit(AdminRecord t) => setState(() {
        _editingId = t.id;
        _editName.text = t.name;
        _editEmail.text = t.subtitle;
      });

  Future<void> _saveEdit(String id) async {
    if (_editName.text.trim().isEmpty || _editEmail.text.trim().isEmpty) {
      _snack('Name and email are required');
      return;
    }
    setState(() => _editSaving = true);
    final ok = await context.read<AdminCubit>().updateTeacher(id, {
      'name': _editName.text.trim(),
      'email': _editEmail.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _editSaving = false;
      if (ok) _editingId = null;
    });
    _snack(ok ? 'Teacher updated' : 'Failed to update teacher');
  }

  Future<void> _delete(String id) async {
    setState(() => _deletingId = id);
    await context.read<AdminCubit>().deleteTeacher(id);
    if (mounted) setState(() => _deletingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    final hasSchool = state.selectedSchoolId != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Teacher Management', style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _createCard(c, state, hasSchool),
        if (hasSchool) ...[
          const SizedBox(height: 16),
          _listCard(c, state.teachers),
        ],
      ],
    );
  }

  // ── Create card ──
  Widget _createCard(AskAideColors c, AdminState state, bool hasSchool) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PickerField(
            label: 'School',
            hint: 'Select school…',
            items: state.schools
                .map((s) => AdminRecord(
                    id: s.id,
                    name: s.code.isEmpty ? s.name : '${s.name} (${s.code})'))
                .toList(),
            selectedId: state.selectedSchoolId,
            onChanged: (v) => context.read<AdminCubit>().selectSchool(v),
          ),
          if (hasSchool) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add New Teachers', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                TextButton.icon(
                  onPressed: () => setState(() => _rows.add(_PersonRow())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            Divider(height: 16, color: c.border),
            Form(
              key: _formKey,
              child: Column(
                children: [for (var i = 0; i < _rows.length; i++) _createRow(c, i)],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _creating ? null : _submit,
                icon: _creating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: Text('Create ${_rows.length} Teacher${_rows.length != 1 ? 's' : ''}'),
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _createRow(AskAideColors c, int i) {
    final r = _rows[i];
    final mobile = context.isMobile;
    final nameField = _tf(c, 'Full Name *', r.name,
        hint: 'John Doe',
        requiredField: true,
        trailing: IconButton(
          tooltip: 'Auto-generate email & password',
          onPressed: () => _generate(i),
          icon: Icon(Icons.auto_fix_high, size: 18, color: c.accent),
        ));
    final emailField = _tf(c, 'Email *', r.email, hint: 'john@school.com', requiredField: true, email: true);
    final passField = _tf(c, 'Password *', r.password, hint: 'Secret123!', requiredField: true, minLen: 6);
    final phoneField = _tf(c, 'Phone', r.phone, hint: '+1234567890');
    final remove = _rows.length > 1
        ? IconButton(
            onPressed: () => setState(() => _rows.removeAt(i).dispose()),
            icon: Icon(Icons.delete_outline, size: 18, color: c.textMuted),
          )
        : const SizedBox(width: 40);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_rows.length > 1)
                  Align(alignment: Alignment.centerRight, child: remove),
                nameField,
                const SizedBox(height: 10),
                emailField,
                const SizedBox(height: 10),
                passField,
                const SizedBox(height: 10),
                phoneField,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: nameField),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: emailField),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: passField),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: phoneField),
                Padding(padding: const EdgeInsets.only(top: 20), child: remove),
              ],
            ),
    );
  }

  Widget _tf(AskAideColors c, String label, TextEditingController ctl,
      {String? hint, bool requiredField = false, bool email = false, int? minLen, Widget? trailing}) {
    final field = TextFormField(
      controller: ctl,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      style: AppTypography.bodySmall(c.textPrimary),
      decoration: InputDecoration(hintText: hint, isDense: true),
      validator: (v) {
        final t = (v ?? '').trim();
        if (requiredField && t.isEmpty) return 'Required';
        if (email && t.isNotEmpty && !RegExp(r'^\S+@\S+$').hasMatch(t)) return 'Invalid';
        if (minLen != null && t.isNotEmpty && t.length < minLen) return 'Min $minLen';
        return null;
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        trailing == null
            ? field
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: field),
                trailing,
              ]),
      ],
    );
  }

  // ── List card ──
  Widget _listCard(AskAideColors c, List<AdminRecord> teachers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('Teachers', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
            const SizedBox(width: 8),
            Text('(${teachers.length})', style: AppTypography.bodySmall(c.textMuted)),
          ]),
          const SizedBox(height: 12),
          if (teachers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: Icons.people_outline,
                title: 'No Teachers Found',
                hint: 'Add teachers with the form above.',
              ),
            )
          else if (context.isMobile)
            Column(children: [for (final t in teachers) _teacherCardMobile(c, t)])
          else ...[
            Row(children: [
              Expanded(flex: 4, child: Text('NAME', style: AppTypography.mono(c.textMuted, size: 10))),
              Expanded(flex: 5, child: Text('EMAIL', style: AppTypography.mono(c.textMuted, size: 10))),
              SizedBox(width: 96, child: Text('ACTIONS', textAlign: TextAlign.right, style: AppTypography.mono(c.textMuted, size: 10))),
            ]),
            Divider(height: 12, color: c.border),
            for (final t in teachers) _teacherRowDesktop(c, t),
          ],
        ],
      ),
    );
  }

  Widget _teacherRowDesktop(AskAideColors c, AdminRecord t) {
    final editing = _editingId == t.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: editing
                ? _inlineField(c, _editName)
                : Text(t.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: editing
                ? _inlineField(c, _editEmail)
                : Text(t.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(c.textSecondary)),
          ),
          SizedBox(width: 96, child: _actions(c, t, editing)),
        ],
      ),
    );
  }

  Widget _teacherCardMobile(AskAideColors c, AdminRecord t) {
    final editing = _editingId == t.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: editing
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _inlineField(c, _editName),
              const SizedBox(height: 8),
              _inlineField(c, _editEmail),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: _actions(c, t, true)),
            ])
          : Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(c.textPrimary)),
                  Text(t.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(c.textMuted)),
                ]),
              ),
              _actions(c, t, false),
            ]),
    );
  }

  Widget _inlineField(AskAideColors c, TextEditingController ctl) => TextField(
        controller: ctl,
        style: AppTypography.bodySmall(c.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
        ),
      );

  Widget _actions(AskAideColors c, AdminRecord t, bool editing) {
    if (editing) {
      return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
        IconButton(
          onPressed: _editSaving ? null : () => _saveEdit(t.id),
          icon: _editSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.check, size: 18, color: c.success),
        ),
        IconButton(
          onPressed: () => setState(() => _editingId = null),
          icon: Icon(Icons.close, size: 18, color: c.textMuted),
        ),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(
        onPressed: () => _openEdit(t),
        icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
      ),
      IconButton(
        onPressed: _deletingId == t.id ? null : () => _delete(t.id),
        icon: _deletingId == t.id
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.delete_outline, size: 18, color: c.danger),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Students tab
// ─────────────────────────────────────────────────────────────────────────────

