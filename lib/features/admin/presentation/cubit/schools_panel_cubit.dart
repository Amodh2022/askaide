import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class SchoolsPanelState extends Equatable {
  const SchoolsPanelState({
    this.isCreating = false,
    this.editing,
    this.saving = false,
    this.deletingIds = const {},
  });

  final bool isCreating;
  final AdminSchool? editing;
  final bool saving;
  final Set<String> deletingIds;

  bool get formOpen => isCreating || editing != null;

  SchoolsPanelState copyWith({bool? saving, Set<String>? deletingIds}) => SchoolsPanelState(
        isCreating: isCreating,
        editing: editing,
        saving: saving ?? this.saving,
        deletingIds: deletingIds ?? this.deletingIds,
      );

  @override
  List<Object?> get props => [isCreating, editing, saving, deletingIds];
}

/// Owns the Schools panel's create/edit form (open state + fields) and the
/// per-school delete-in-progress set. Delegates actual mutations to
/// [AdminCubit], which owns the shared school list.
class SchoolsPanelCubit extends Cubit<SchoolsPanelState> {
  SchoolsPanelCubit()
      : formKey = GlobalKey<FormState>(),
        name = TextEditingController(),
        code = TextEditingController(),
        address = TextEditingController(),
        board = TextEditingController(),
        phone = TextEditingController(),
        email = TextEditingController(),
        website = TextEditingController(),
        super(const SchoolsPanelState());

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController code;
  final TextEditingController address;
  final TextEditingController board;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController website;

  List<TextEditingController> get _all => [name, code, address, board, phone, email, website];

  void _resetFields() {
    for (final c in _all) {
      c.clear();
    }
  }

  void startCreate() {
    emit(SchoolsPanelState(isCreating: true, deletingIds: state.deletingIds));
    _resetFields();
  }

  void startEdit(AdminSchool s) {
    emit(SchoolsPanelState(editing: s, deletingIds: state.deletingIds));
    _resetFields();
    name.text = s.name;
    code.text = s.code;
  }

  void cancel() {
    emit(SchoolsPanelState(deletingIds: state.deletingIds));
    _resetFields();
  }

  Future<bool> submit(AdminCubit admin) async {
    emit(state.copyWith(saving: true));
    final editing = state.editing;
    final bool ok;
    if (editing != null) {
      ok = await admin.updateSchool(editing.id, {
        'schoolName': name.text.trim(),
        'schoolCode': code.text.trim(),
      });
    } else {
      ok = await admin.createSchool({
        'schoolName': name.text.trim(),
        'schoolCode': code.text.trim(),
        'schoolAddress': address.text.trim(),
        'schoolBoard': board.text.trim(),
        if (phone.text.trim().isNotEmpty) 'schoolPhone': phone.text.trim(),
        if (email.text.trim().isNotEmpty) 'schoolEmail': email.text.trim(),
        if (website.text.trim().isNotEmpty) 'schoolWebsite': website.text.trim(),
      });
    }
    if (isClosed) return ok;
    emit(state.copyWith(saving: false));
    if (ok) cancel();
    return ok;
  }

  Future<bool> deleteSchool(AdminCubit admin, String id) async {
    emit(state.copyWith(deletingIds: {...state.deletingIds, id}));
    final success = await admin.deleteSchool(id);
    if (isClosed) return success;
    emit(state.copyWith(deletingIds: {...state.deletingIds}..remove(id)));
    return success;
  }

  @override
  Future<void> close() {
    for (final c in _all) {
      c.dispose();
    }
    return super.close();
  }
}
