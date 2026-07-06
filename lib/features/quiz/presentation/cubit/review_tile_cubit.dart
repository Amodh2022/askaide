import 'package:flutter_bloc/flutter_bloc.dart';

/// Expanded/collapsed state for a single question-review row on the quiz
/// result page. One instance per tile.
class ReviewTileCubit extends Cubit<bool> {
  ReviewTileCubit() : super(false);

  void toggle() => emit(!state);
}
