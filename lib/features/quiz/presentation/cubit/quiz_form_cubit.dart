import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../quiz_teacher_cubits.dart';

/// Owns the "create quiz" form: title/description controllers plus the
/// settings sliders/toggles/deadline, reusing [QuizSettingsDraft] as the
/// Cubit state since it already has the copyWith/clear-flag shape needed.
class QuizFormCubit extends Cubit<QuizSettingsDraft> {
  QuizFormCubit()
      : title = TextEditingController(),
        description = TextEditingController(),
        super(const QuizSettingsDraft(timeLimit: 30));

  final TextEditingController title;
  final TextEditingController description;

  void setTimeLimit(int value) => emit(state.copyWith(timeLimit: value));
  void setShuffleQuestions(bool value) => emit(state.copyWith(shuffleQuestions: value));
  void setShuffleOptions(bool value) => emit(state.copyWith(shuffleOptions: value));
  void setShowAnswersAfter(String value) => emit(state.copyWith(showAnswersAfter: value));
  void setAllowedAttempts(int value) => emit(state.copyWith(allowedAttempts: value));
  void setPassingPercentage(int value) => emit(state.copyWith(passingPercentage: value));

  void setDeadline(DateTime? value) => emit(
      value == null ? state.copyWith(clearDeadline: true) : state.copyWith(deadline: value));

  Future<void> submit(QuizBuilderCubit builder) =>
      builder.create(title.text.trim(), description.text.trim(), state);

  @override
  Future<void> close() {
    title.dispose();
    description.dispose();
    return super.close();
  }
}
