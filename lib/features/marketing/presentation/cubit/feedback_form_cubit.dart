import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/endpoints.dart';

class FeedbackFormState extends Equatable {
  const FeedbackFormState({this.rating = 0, this.submitting = false});

  final int rating;
  final bool submitting;

  FeedbackFormState copyWith({int? rating, bool? submitting}) => FeedbackFormState(
        rating: rating ?? this.rating,
        submitting: submitting ?? this.submitting,
      );

  @override
  List<Object?> get props => [rating, submitting];
}

/// Owns the public `/feedback` form: name/email/message controllers, star
/// rating, and the submit flow.
class MarketingFeedbackCubit extends Cubit<FeedbackFormState> {
  MarketingFeedbackCubit(this._dio)
      : name = TextEditingController(),
        email = TextEditingController(),
        message = TextEditingController(),
        super(const FeedbackFormState());

  final Dio _dio;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController message;

  void setRating(int value) => emit(state.copyWith(rating: value));

  Future<bool> submit() async {
    emit(state.copyWith(submitting: true));
    var ok = true;
    try {
      await _dio.post(Endpoints.feedback, data: {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'feedback': message.text.trim(),
        if (state.rating > 0) 'rating': state.rating,
      });
    } catch (_) {
      ok = false;
    }
    if (isClosed) return ok;
    if (ok) {
      name.clear();
      email.clear();
      message.clear();
      emit(const FeedbackFormState());
    } else {
      emit(state.copyWith(submitting: false));
    }
    return ok;
  }

  @override
  Future<void> close() {
    name.dispose();
    email.dispose();
    message.dispose();
    return super.close();
  }
}
