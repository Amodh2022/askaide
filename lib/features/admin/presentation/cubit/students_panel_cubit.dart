import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One editable student row for the Students panel's multi-add create form.
/// Defined here (rather than reusing the private `_PersonRow` in the admin
/// panels' shared.dart part-file) because this cubit lives outside that
/// `part of` library and can't see its private members.
class StudentRowForm {
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

/// Deliberately NOT Equatable: [rows] holds [StudentRowForm]s whose
/// [TextEditingController]s are mutated in place (e.g. credential
/// generation). Content-based equality would treat that as "no change" and
/// suppress the rebuild, so state identity (a fresh instance per copyWith)
/// is what drives `Cubit.emit`'s change detection here.
class StudentsPanelState {
  const StudentsPanelState({
    this.rows = const [],
    this.creating = false,
    this.editingId,
    this.editSaving = false,
    this.deletingId,
  });

  final List<StudentRowForm> rows;
  final bool creating;
  final String? editingId;
  final bool editSaving;
  final String? deletingId;

  StudentsPanelState copyWith({
    List<StudentRowForm>? rows,
    bool? creating,
    String? editingId,
    bool? editSaving,
    String? deletingId,
    bool clearEditingId = false,
    bool clearDeletingId = false,
  }) =>
      StudentsPanelState(
        rows: rows ?? this.rows,
        creating: creating ?? this.creating,
        editingId: clearEditingId ? null : (editingId ?? this.editingId),
        editSaving: editSaving ?? this.editSaving,
        deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
      );
}

/// Owns the Students panel's local UI state: the multi-row create form, the
/// inline-edit mode + its controllers, and per-row create/save/delete busy
/// flags. Actual mutations are dispatched by the widget via `AdminCubit`
/// (the admin feature's shared data cubit) — this cubit only tracks the
/// panel's own view state.
class StudentsPanelCubit extends Cubit<StudentsPanelState> {
  StudentsPanelCubit()
      : editName = TextEditingController(),
        editEmail = TextEditingController(),
        super(StudentsPanelState(rows: [StudentRowForm()]));

  final TextEditingController editName;
  final TextEditingController editEmail;

  void addRow() => emit(state.copyWith(rows: [...state.rows, StudentRowForm()]));

  void removeRowAt(int index) {
    final next = List<StudentRowForm>.from(state.rows);
    next.removeAt(index).dispose();
    emit(state.copyWith(rows: next));
  }

  /// Mutates row [index]'s email/password controllers in place (e.g.
  /// generated credentials) and forces a rebuild.
  void setRowCredentials(int index, String email, String password) {
    state.rows[index].email.text = email;
    state.rows[index].password.text = password;
    emit(state.copyWith());
  }

  void setCreating(bool value) => emit(state.copyWith(creating: value));

  /// Disposes the current rows and starts a fresh single blank row (called
  /// after a successful bulk create).
  void resetRows() {
    for (final r in state.rows) {
      r.dispose();
    }
    emit(state.copyWith(rows: [StudentRowForm()]));
  }

  void openEdit(String id, String name, String email) {
    editName.text = name;
    editEmail.text = email;
    emit(state.copyWith(editingId: id));
  }

  void cancelEdit() => emit(state.copyWith(clearEditingId: true));

  void setEditSaving(bool value) => emit(state.copyWith(editSaving: value));

  void editSaved() => emit(state.copyWith(editSaving: false, clearEditingId: true));

  void setDeleting(String? id) =>
      emit(state.copyWith(deletingId: id, clearDeletingId: id == null));

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
