import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ai_assistant/domain/repositories/ai_assistant_repository.dart';

class TeacherAiGeneratorState extends Equatable {
  const TeacherAiGeneratorState({this.loading = false, this.answer});

  final bool loading;
  final String? answer;

  @override
  List<Object?> get props => [loading, answer];
}

/// Owns the teacher AI generator prompt controller and the single-shot ask
/// flow (mirrors the frontend's teacher AI generator panel).
class TeacherAiGeneratorCubit extends Cubit<TeacherAiGeneratorState> {
  TeacherAiGeneratorCubit(this._repo)
      : prompt = TextEditingController(),
        super(const TeacherAiGeneratorState());

  final AiTeacherToolsRepository _repo;
  final TextEditingController prompt;

  Future<void> generate() async {
    final text = prompt.text.trim();
    if (text.isEmpty) return;
    emit(const TeacherAiGeneratorState(loading: true));
    final result = await _repo.ask(text);
    if (isClosed) return;
    emit(TeacherAiGeneratorState(
      answer: result.fold((f) => 'Error: ${f.message}', (a) => a),
    ));
  }

  @override
  Future<void> close() {
    prompt.dispose();
    return super.close();
  }
}
