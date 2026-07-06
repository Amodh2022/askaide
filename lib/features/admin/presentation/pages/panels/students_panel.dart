part of '../admin_dashboard_page.dart';

class _StudentsPanel extends StatelessWidget {
  const _StudentsPanel();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentsPanelCubit>(
      create: (_) => sl<StudentsPanelCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  void _snack(BuildContext context, String m) =>
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

  void _generate(BuildContext context, int i) {
    final panelCubit = context.read<StudentsPanelCubit>();
    final name = panelCubit.state.rows[i].name.text.trim();
    if (name.isEmpty) {
      _snack(context, 'Please enter a name first');
      return;
    }
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final rand = DateTime.now().microsecondsSinceEpoch % 1000;
    panelCubit.setRowCredentials(i, '$clean.$rand@school.com', _genPassword());
    _snack(context, 'Credentials generated!');
  }

  Future<void> _submit(BuildContext context, GlobalKey<FormState> formKey) async {
    final adminCubit = context.read<AdminCubit>();
    final panelCubit = context.read<StudentsPanelCubit>();
    final schoolId = adminCubit.state.selectedSchoolId;
    if (schoolId == null) {
      _snack(context, 'Please select a school first');
      return;
    }
    if (!formKey.currentState!.validate()) return;
    panelCubit.setCreating(true);
    final rows = panelCubit.state.rows;
    final payload = [
      for (final r in rows)
        {
          'name': r.name.text.trim(),
          'email': r.email.text.trim(),
          'password': r.password.text.trim(),
          if (r.phone.text.trim().isNotEmpty) 'phone': r.phone.text.trim(),
        }
    ];
    final n = payload.length;
    final ok = await adminCubit.createStudents(payload);
    if (!context.mounted) return;
    panelCubit.setCreating(false);
    _snack(context, ok ? 'Successfully created $n student${n != 1 ? 's' : ''}' : 'Failed to create students');
    if (ok) panelCubit.resetRows();
  }

  void _openEdit(BuildContext context, AdminRecord s) =>
      context.read<StudentsPanelCubit>().openEdit(s.id, s.name, s.subtitle);

  Future<void> _saveEdit(BuildContext context, String id) async {
    final panelCubit = context.read<StudentsPanelCubit>();
    if (panelCubit.editName.text.trim().isEmpty || panelCubit.editEmail.text.trim().isEmpty) {
      _snack(context, 'Name and email are required');
      return;
    }
    panelCubit.setEditSaving(true);
    final ok = await context.read<AdminCubit>().updateStudent(id, {
      'name': panelCubit.editName.text.trim(),
      'email': panelCubit.editEmail.text.trim(),
    });
    if (!context.mounted) return;
    if (ok) {
      panelCubit.editSaved();
    } else {
      panelCubit.setEditSaving(false);
    }
    _snack(context, ok ? 'Student updated' : 'Failed to update student');
  }

  Future<void> _delete(BuildContext context, String id) async {
    final panelCubit = context.read<StudentsPanelCubit>();
    panelCubit.setDeleting(id);
    await context.read<AdminCubit>().deleteStudent(id);
    panelCubit.setDeleting(null);
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    final hasSchool = state.selectedSchoolId != null;
    final formKey = GlobalKey<FormState>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Student Management', style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _createCard(context, c, state, hasSchool, formKey),
        if (hasSchool) ...[
          const SizedBox(height: 16),
          _listCard(context, c, state.students),
        ],
      ],
    );
  }

  Widget _createCard(BuildContext context, AskAideColors c, AdminState state, bool hasSchool,
      GlobalKey<FormState> formKey) {
    final panelState = context.watch<StudentsPanelCubit>().state;
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
                Text('Add New Students', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                TextButton.icon(
                  onPressed: () => context.read<StudentsPanelCubit>().addRow(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            Divider(height: 16, color: c.border),
            Form(
              key: formKey,
              child: Column(
                children: [
                  for (var i = 0; i < panelState.rows.length; i++)
                    _createRow(context, c, panelState, i),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: panelState.creating ? null : () => _submit(context, formKey),
                icon: panelState.creating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: Text('Create ${panelState.rows.length} Student${panelState.rows.length != 1 ? 's' : ''}'),
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _createRow(BuildContext context, AskAideColors c, StudentsPanelState panelState, int i) {
    final r = panelState.rows[i];
    final mobile = context.isMobile;
    final nameField = AdminFormField(
        label: 'Full Name *',
        controller: r.name,
        hint: 'Jane Doe',
        requiredField: true,
        trailing: IconButton(
          tooltip: 'Auto-generate email & password',
          onPressed: () => _generate(context, i),
          icon: Icon(Icons.auto_fix_high, size: 18, color: c.accent),
        ));
    final emailField = AdminFormField(
        label: 'Email *',
        controller: r.email,
        hint: 'jane@school.com',
        requiredField: true,
        email: true);
    final passField = AdminFormField(
        label: 'Password *',
        controller: r.password,
        hint: 'Secret123!',
        requiredField: true,
        minLen: 6,
        minLenMessage: 'Min 6');
    final phoneField = AdminFormField(label: 'Phone', controller: r.phone, hint: '+1234567890');
    final remove = panelState.rows.length > 1
        ? IconButton(
            onPressed: () => context.read<StudentsPanelCubit>().removeRowAt(i),
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
                if (panelState.rows.length > 1)
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

  Widget _listCard(BuildContext context, AskAideColors c, List<AdminRecord> students) {
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
            Text('Students', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
            const SizedBox(width: 8),
            Text('(${students.length})', style: AppTypography.bodySmall(c.textMuted)),
          ]),
          const SizedBox(height: 12),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: Icons.school_outlined,
                title: 'No Students Found',
                hint: 'Add students with the form above.',
              ),
            )
          else if (context.isMobile)
            Column(children: [for (final s in students) _studentCardMobile(context, c, s)])
          else ...[
            Row(children: [
              Expanded(flex: 4, child: Text('NAME', style: AppTypography.mono(c.textMuted, size: 10))),
              Expanded(flex: 5, child: Text('EMAIL', style: AppTypography.mono(c.textMuted, size: 10))),
              SizedBox(width: 96, child: Text('ACTIONS', textAlign: TextAlign.right, style: AppTypography.mono(c.textMuted, size: 10))),
            ]),
            Divider(height: 12, color: c.border),
            for (final s in students) _studentRowDesktop(context, c, s),
          ],
        ],
      ),
    );
  }

  Widget _studentRowDesktop(BuildContext context, AskAideColors c, AdminRecord s) {
    final panelCubit = context.watch<StudentsPanelCubit>();
    final editing = panelCubit.state.editingId == s.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: editing
                ? _inlineField(c, panelCubit.editName)
                : Text(s.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: editing
                ? _inlineField(c, panelCubit.editEmail)
                : Text(s.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(c.textSecondary)),
          ),
          SizedBox(width: 96, child: _actions(context, c, s, editing)),
        ],
      ),
    );
  }

  Widget _studentCardMobile(BuildContext context, AskAideColors c, AdminRecord s) {
    final panelCubit = context.watch<StudentsPanelCubit>();
    final editing = panelCubit.state.editingId == s.id;
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
              _inlineField(c, panelCubit.editName),
              const SizedBox(height: 8),
              _inlineField(c, panelCubit.editEmail),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: _actions(context, c, s, true)),
            ])
          : Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(c.textPrimary)),
                  Text(s.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(c.textMuted)),
                ]),
              ),
              _actions(context, c, s, false),
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

  Widget _actions(BuildContext context, AskAideColors c, AdminRecord s, bool editing) {
    final panelState = context.watch<StudentsPanelCubit>().state;
    if (editing) {
      return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
        IconButton(
          onPressed: panelState.editSaving ? null : () => _saveEdit(context, s.id),
          icon: panelState.editSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.check, size: 18, color: c.success),
        ),
        IconButton(
          onPressed: () => context.read<StudentsPanelCubit>().cancelEdit(),
          icon: Icon(Icons.close, size: 18, color: c.textMuted),
        ),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(
        onPressed: () => _openEdit(context, s),
        icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
      ),
      IconButton(
        onPressed: panelState.deletingId == s.id ? null : () => _delete(context, s.id),
        icon: panelState.deletingId == s.id
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.delete_outline, size: 18, color: c.danger),
      ),
    ]);
  }
}

/// Schools tab — faithful port of React `SchoolManagement`: a header with an
/// "Add School" button, an inline create/edit form (7 fields on create, just
/// name + code on edit), and a responsive card grid with per-card edit.
