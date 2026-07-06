import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/teacher_feature.dart';

class StudentFilterState extends Equatable {
  const StudentFilterState({
    this.search = '',
    this.statusFilter = 'all',
    this.sortBy = 'mastery',
    this.sortDesc = true,
  });

  final String search;
  final String statusFilter;
  final String sortBy;
  final bool sortDesc;

  StudentFilterState copyWith({
    String? search,
    String? statusFilter,
    String? sortBy,
    bool? sortDesc,
  }) =>
      StudentFilterState(
        search: search ?? this.search,
        statusFilter: statusFilter ?? this.statusFilter,
        sortBy: sortBy ?? this.sortBy,
        sortDesc: sortDesc ?? this.sortDesc,
      );

  @override
  List<Object?> get props => [search, statusFilter, sortBy, sortDesc];
}

/// Owns the client-side search/filter/sort controls over an already-loaded
/// student roster (mirrors the teacher students-view toolbar).
class StudentFilterCubit extends Cubit<StudentFilterState> {
  StudentFilterCubit() : super(const StudentFilterState());

  void setSearch(String value) => emit(state.copyWith(search: value));
  void setStatusFilter(String value) => emit(state.copyWith(statusFilter: value));
  void setSortBy(String value) => emit(state.copyWith(sortBy: value));
  void toggleSortDesc() => emit(state.copyWith(sortDesc: !state.sortDesc));

  List<StudentRow> apply(List<StudentRow> list) {
    var result = [...list];
    if (state.search.isNotEmpty) {
      final q = state.search.toLowerCase();
      result = result
          .where((s) => s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q))
          .toList();
    }
    if (state.statusFilter != 'all') {
      result = result.where((s) {
        final st = s.status.toUpperCase();
        switch (state.statusFilter) {
          case 'struggling':
            return st.contains('NEEDS') || st.contains('WEAK');
          case 'top':
            return st == 'STRONG';
          case 'inactive':
            return st == 'INACTIVE' || s.daysInactive > 3;
          default:
            return true;
        }
      }).toList();
    }
    result.sort((a, b) {
      int cmp;
      switch (state.sortBy) {
        case 'name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'coverage':
          cmp = a.coverage.compareTo(b.coverage);
        case 'lastActive':
          cmp = a.lastPracticed.compareTo(b.lastPracticed);
        default:
          cmp = a.mastery.compareTo(b.mastery);
      }
      return state.sortDesc ? -cmp : cmp;
    });
    return result;
  }
}
