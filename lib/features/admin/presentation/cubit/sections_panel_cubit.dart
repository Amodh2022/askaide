import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class SectionsPanelState extends Equatable {
  const SectionsPanelState({
    this.classId,
    this.sections = const [],
    this.loading = false,
  });

  final String? classId;
  final List<AdminSection> sections;
  final bool loading;

  SectionsPanelState copyWith({
    String? classId,
    List<AdminSection>? sections,
    bool? loading,
  }) =>
      SectionsPanelState(
        classId: classId ?? this.classId,
        sections: sections ?? this.sections,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [classId, sections, loading];
}

/// Owns the Sections panel's selected class + loaded section list for the
/// currently selected school (selection itself lives in [AdminCubit]).
class SectionsPanelCubit extends Cubit<SectionsPanelState> {
  SectionsPanelCubit(this._repo) : super(const SectionsPanelState());
  final AdminRepository _repo;

  void resetClass() => emit(const SectionsPanelState());

  Future<void> selectClass(String classId, String schoolId) async {
    emit(SectionsPanelState(classId: classId));
    await load(schoolId);
  }

  Future<void> load(String schoolId) async {
    final classId = state.classId;
    if (classId == null) return;
    emit(state.copyWith(loading: true));
    final r = await _repo.sectionsDetailed(schoolId, classId);
    if (isClosed) return;
    emit(state.copyWith(loading: false, sections: r.getOrElse(() => const [])));
  }
}
