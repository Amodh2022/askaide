import 'package:flutter_bloc/flutter_bloc.dart';

/// Search query for the quiz history title filter.
class QuizHistorySearchCubit extends Cubit<String> {
  QuizHistorySearchCubit() : super('');

  void setQuery(String value) => emit(value);
}
