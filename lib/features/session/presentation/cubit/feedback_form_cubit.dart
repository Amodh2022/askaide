import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/session_repository.dart';

class FeedbackFormState extends Equatable {
  const FeedbackFormState({
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  final bool submitting;
  final bool submitted;
  final String? error;

  @override
  List<Object?> get props => [submitting, submitted, error];
}

/// Owns the in-session "Report" feedback dialog: name/email/feedback
/// controllers and the submit/error/success flow.
class FeedbackFormCubit extends Cubit<FeedbackFormState> {
  FeedbackFormCubit(this._repository)
      : name = TextEditingController(),
        email = TextEditingController(),
        feedback = TextEditingController(),
        super(const FeedbackFormState());

  final SessionRepository _repository;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController feedback;

  Future<void> submit() async {
    final name = this.name.text.trim();
    final feedback = this.feedback.text.trim();
    if (name.isEmpty || feedback.isEmpty) {
      emit(const FeedbackFormState(error: 'Name and feedback are required.'));
      return;
    }
    emit(const FeedbackFormState(submitting: true));
    final email = this.email.text.trim();
    final result = await _repository.submitFeedback(
      name: name,
      feedback: feedback,
      email: email.isEmpty ? null : email,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(const FeedbackFormState(
          error: 'Something went wrong. Please try again.')),
      (_) => emit(const FeedbackFormState(submitted: true)),
    );
  }

  @override
  Future<void> close() {
    name.dispose();
    email.dispose();
    feedback.dispose();
    return super.close();
  }
}
