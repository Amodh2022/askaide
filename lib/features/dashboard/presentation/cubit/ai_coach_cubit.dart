import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiCoachState extends Equatable {
  const AiCoachState({
    this.open = false,
    this.loading = false,
    this.insight,
    this.error,
  });

  final bool open;
  final bool loading;
  final String? insight;
  final String? error;

  AiCoachState copyWith({bool? open}) => AiCoachState(
        open: open ?? this.open,
        loading: loading,
        insight: insight,
        error: error,
      );

  @override
  List<Object?> get props => [open, loading, insight, error];
}

/// Owns the collapsible "AI Learning Coach" card: lazily loads the markdown
/// insight on first expand, then just toggles visibility.
class AiCoachCubit extends Cubit<AiCoachState> {
  AiCoachCubit() : super(const AiCoachState());

  Future<void> toggle(Future<String?> Function() loader) async {
    if (state.insight != null) {
      emit(state.copyWith(open: !state.open));
      return;
    }
    emit(const AiCoachState(loading: true));
    final result = await loader();
    if (isClosed) return;
    if (result == null || result.isEmpty) {
      emit(const AiCoachState(
          error: 'Failed to load AI insight. Please try again.'));
    } else {
      emit(AiCoachState(open: true, insight: result));
    }
  }
}
