part of '../admin_dashboard_page.dart';

class _TeachersPanel extends StatelessWidget {
  const _TeachersPanel();

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminCubit>();
    return BlocProvider<TeachersPanelCubit>(
      create: (_) => sl<TeachersPanelCubit>(param1: admin),
      child: Builder(builder: _buildBody),
    );
  }

  void _snack(BuildContext context, String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _generate(BuildContext context, int i) {
    final err = context.read<TeachersPanelCubit>().generateCredentials(i);
    _snack(context, err ?? 'Credentials generated!');
  }

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<TeachersPanelCubit>();
    if (!cubit.formKey.currentState!.validate()) return;
    final msg = await cubit.submit();
    if (!context.mounted || msg == null) return;
    _snack(context, msg);
  }

  Future<void> _saveEdit(BuildContext context, String id) async {
    final msg = await context.read<TeachersPanelCubit>().saveEdit(id);
    if (!context.mounted || msg == null) return;
    _snack(context, msg);
  }

  Future<void> _delete(BuildContext context, String id) =>
      context.read<TeachersPanelCubit>().delete(id);

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final adminState = context.watch<AdminCubit>().state;
    final panelState = context.watch<TeachersPanelCubit>().state;
    final hasSchool = adminState.selectedSchoolId != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Teacher Management', style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _createCard(context, c, adminState, panelState, hasSchool),
        if (hasSchool) ...[
          const SizedBox(height: 16),
          _listCard(context, c, adminState.teachers, panelState),
        ],
      ],
    );
  }

  // ── Create card ──
  Widget _createCard(BuildContext context, AskAideColors c, AdminState state,
      TeachersPanelState panelState, bool hasSchool) {
    final cubit = context.read<TeachersPanelCubit>();
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
                  onPressed: cubit.addRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            Divider(height: 16, color: c.border),
            Form(
              key: cubit.formKey,
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
                onPressed: panelState.creating ? null : () => _submit(context),
                icon: panelState.creating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: Text('Create ${panelState.rows.length} Teacher${panelState.rows.length != 1 ? 's' : ''}'),
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _createRow(BuildContext context, AskAideColors c, TeachersPanelState panelState, int i) {
    final cubit = context.read<TeachersPanelCubit>();
    final r = panelState.rows[i];
    final mobile = context.isMobile;
    final nameField = AdminFormField(
        label: 'Full Name *',
        controller: r.name,
        hint: 'John Doe',
        requiredField: true,
        trailing: IconButton(
          tooltip: 'Auto-generate email & password',
          onPressed: () => _generate(context, i),
          icon: Icon(Icons.auto_fix_high, size: 18, color: c.accent),
        ));
    final emailField = AdminFormField(
        label: 'Email *',
        controller: r.email,
        hint: 'john@school.com',
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
            onPressed: () => cubit.removeRow(i),
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

  // ── List card ──
  Widget _listCard(BuildContext context, AskAideColors c, List<AdminRecord> teachers,
      TeachersPanelState panelState) {
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
            Column(children: [for (final t in teachers) _teacherCardMobile(context, c, t, panelState)])
          else ...[
            Row(children: [
              Expanded(flex: 4, child: Text('NAME', style: AppTypography.mono(c.textMuted, size: 10))),
              Expanded(flex: 5, child: Text('EMAIL', style: AppTypography.mono(c.textMuted, size: 10))),
              SizedBox(width: 96, child: Text('ACTIONS', textAlign: TextAlign.right, style: AppTypography.mono(c.textMuted, size: 10))),
            ]),
            Divider(height: 12, color: c.border),
            for (final t in teachers) _teacherRowDesktop(context, c, t, panelState),
          ],
        ],
      ),
    );
  }

  Widget _teacherRowDesktop(BuildContext context, AskAideColors c, AdminRecord t, TeachersPanelState panelState) {
    final cubit = context.read<TeachersPanelCubit>();
    final editing = panelState.editingId == t.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: editing
                ? _inlineField(c, cubit.editName)
                : Text(t.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: editing
                ? _inlineField(c, cubit.editEmail)
                : Text(t.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(c.textSecondary)),
          ),
          SizedBox(width: 96, child: _actions(context, c, t, editing, panelState)),
        ],
      ),
    );
  }

  Widget _teacherCardMobile(BuildContext context, AskAideColors c, AdminRecord t, TeachersPanelState panelState) {
    final cubit = context.read<TeachersPanelCubit>();
    final editing = panelState.editingId == t.id;
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
              _inlineField(c, cubit.editName),
              const SizedBox(height: 8),
              _inlineField(c, cubit.editEmail),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: _actions(context, c, t, true, panelState)),
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
              _actions(context, c, t, false, panelState),
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

  Widget _actions(BuildContext context, AskAideColors c, AdminRecord t, bool editing, TeachersPanelState panelState) {
    final cubit = context.read<TeachersPanelCubit>();
    if (editing) {
      return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
        IconButton(
          onPressed: panelState.editSaving ? null : () => _saveEdit(context, t.id),
          icon: panelState.editSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.check, size: 18, color: c.success),
        ),
        IconButton(
          onPressed: cubit.cancelEdit,
          icon: Icon(Icons.close, size: 18, color: c.textMuted),
        ),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(
        onPressed: () => cubit.openEdit(t),
        icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
      ),
      IconButton(
        onPressed: panelState.deletingId == t.id ? null : () => _delete(context, t.id),
        icon: panelState.deletingId == t.id
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.delete_outline, size: 18, color: c.danger),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Students tab
// ─────────────────────────────────────────────────────────────────────────────
