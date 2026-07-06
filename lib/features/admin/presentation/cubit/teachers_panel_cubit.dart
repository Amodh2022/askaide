import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

/// One editable teacher row used in the Teachers panel's create form.
class TeacherFormRow {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
  }
}

class TeachersPanelState extends Equatable {
  const TeachersPanelState({
    this.rows = const [],
    this.creating = false,
    this.editingId,
    this.editSaving = false,
    this.deletingId,
    this.rev = 0,
  });

  final List<TeacherFormRow> rows;
  final bool creating;
  final String? editingId;
  final bool editSaving;
  final String? deletingId;

  /// Bumped whenever a row's controller text is mutated programmatically
  /// (e.g. auto-generated credentials) so equatable state comparison still
  /// sees a change and rebuilds, even though `rows`' identity is unchanged.
  final int rev;

  TeachersPanelState copyWith({
    List<TeacherFormRow>? rows,
    bool? creating,
    String? editingId,
    bool? editSaving,
    String? deletingId,
    int? rev,
    bool clearEditingId = false,
    bool clearDeletingId = false,
  }) =>
      TeachersPanelState(
        rows: rows ?? this.rows,
        creating: creating ?? this.creating,
        editingId: clearEditingId ? null : (editingId ?? this.editingId),
        editSaving: editSaving ?? this.editSaving,
        deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
        rev: rev ?? this.rev,
      );

  @override
  List<Object?> get props => [rows, creating, editingId, editSaving, deletingId, rev];
}

/// Owns the Teachers panel's create-form rows, inline-edit fields, and
/// busy/deleting flags. Delegates the actual network calls to [AdminCubit],
/// which owns the shared teacher list + selected school.
class TeachersPanelCubit extends Cubit<TeachersPanelState> {
  TeachersPanelCubit(this._admin)
      : formKey = GlobalKey<FormState>(),
        editName = TextEditingController(),
        editEmail = TextEditingController(),
        super(TeachersPanelState(rows: [TeacherFormRow()]));

  final AdminCubit _admin;
  final GlobalKey<FormState> formKey;
  final TextEditingController editName;
  final TextEditingController editEmail;

  void addRow() => emit(state.copyWith(rows: [...state.rows, TeacherFormRow()]));

  void removeRow(int index) {
    final next = List<TeacherFormRow>.from(state.rows);
    next.removeAt(index).dispose();
    emit(state.copyWith(rows: next));
  }

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

  /// Returns an error message if generation couldn't proceed (empty name).
  String? generateCredentials(int index) {
    final row = state.rows[index];
    final name = row.name.text.trim();
    if (name.isEmpty) return 'Please enter a name first';
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final rand = DateTime.now().microsecondsSinceEpoch % 1000;
    row.email.text = '$clean.$rand@school.com';
    row.password.text = _genPassword();
    emit(state.copyWith(rev: state.rev + 1));
    return null;
  }

  /// Returns a status message to show the user, or null if the caller should
  /// stay silent (e.g. form validation already failed).
  Future<String?> submit() async {
    final schoolId = _admin.state.selectedSchoolId;
    if (schoolId == null) return 'Please select a school first';
    emit(state.copyWith(creating: true));
    final payload = [
      for (final r in state.rows)
        {
          'name': r.name.text.trim(),
          'email': r.email.text.trim(),
          'password': r.password.text.trim(),
          if (r.phone.text.trim().isNotEmpty) 'phone': r.phone.text.trim(),
        }
    ];
    final n = payload.length;
    final ok = await _admin.createTeachers(payload);
    if (isClosed) return null;
    if (ok) {
      for (final r in state.rows) {
        r.dispose();
      }
      emit(state.copyWith(creating: false, rows: [TeacherFormRow()]));
    } else {
      emit(state.copyWith(creating: false));
    }
    return ok ? 'Successfully created $n teacher${n != 1 ? 's' : ''}' : 'Failed to create teachers';
  }

  void openEdit(AdminRecord t) {
    editName.text = t.name;
    editEmail.text = t.subtitle;
    emit(state.copyWith(editingId: t.id));
  }

  void cancelEdit() => emit(state.copyWith(clearEditingId: true));

  Future<String?> saveEdit(String id) async {
    if (editName.text.trim().isEmpty || editEmail.text.trim().isEmpty) {
      return 'Name and email are required';
    }
    emit(state.copyWith(editSaving: true));
    final ok = await _admin.updateTeacher(id, {
      'name': editName.text.trim(),
      'email': editEmail.text.trim(),
    });
    if (isClosed) return null;
    emit(state.copyWith(editSaving: false, clearEditingId: ok));
    return ok ? 'Teacher updated' : 'Failed to update teacher';
  }

  Future<void> delete(String id) async {
    emit(state.copyWith(deletingId: id));
    await _admin.deleteTeacher(id);
    if (isClosed) return;
    emit(state.copyWith(clearDeletingId: true));
  }

  @override
  Future<void> close() {
    for (final r in state.rows) {
      r.dispose();
    }
    editName.dispose();
    editEmail.dispose();
    return super.close();
  }
}
