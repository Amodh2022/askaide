import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuizListFilterState extends Equatable {
  const QuizListFilterState({this.query = '', this.statusFilter = ''});

  final String query;
  /// '' | available | in_progress | completed
  final String statusFilter;

  QuizListFilterState copyWith({String? query, String? statusFilter}) =>
      QuizListFilterState(
        query: query ?? this.query,
        statusFilter: statusFilter ?? this.statusFilter,
      );

  @override
  List<Object?> get props => [query, statusFilter];
}

/// Owns the client-side search + status filter on the student quiz list.
class QuizListFilterCubit extends Cubit<QuizListFilterState> {
  QuizListFilterCubit() : super(const QuizListFilterState());

  void setQuery(String value) => emit(state.copyWith(query: value));
  void setStatusFilter(String value) => emit(state.copyWith(statusFilter: value));
}
