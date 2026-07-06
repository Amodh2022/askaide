import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/nps_survey_dialog.dart';

class NpsSurveyState extends Equatable {
  const NpsSurveyState({this.score, this.submitted = false});

  final int? score;
  final bool submitted;

  NpsSurveyState copyWith({int? score, bool? submitted}) => NpsSurveyState(
        score: score ?? this.score,
        submitted: submitted ?? this.submitted,
      );

  @override
  List<Object?> get props => [score, submitted];
}

/// Owns the NPS survey dialog's score picker, comment controller, and
/// submitted flag. The delayed dialog dismissal stays in the widget (it needs
/// [BuildContext]/`Navigator`).
class NpsSurveyCubit extends Cubit<NpsSurveyState> {
  NpsSurveyCubit()
      : comment = TextEditingController(),
        super(const NpsSurveyState());

  final TextEditingController comment;

  void selectScore(int value) => emit(state.copyWith(score: value));

  /// Marks the survey submitted and returns the result, or `null` if no
  /// score was picked yet.
  NpsResult? submit() {
    final score = state.score;
    if (score == null) return null;
    emit(state.copyWith(submitted: true));
    final text = comment.text.trim();
    return NpsResult(score: score, comment: text.isEmpty ? null : text);
  }

  @override
  Future<void> close() {
    comment.dispose();
    return super.close();
  }
}
