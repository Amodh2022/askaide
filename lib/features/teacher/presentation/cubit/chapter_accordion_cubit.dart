import 'package:flutter_bloc/flutter_bloc.dart';

/// Which chapter accordions are expanded in the teacher student-detail view.
class ChapterAccordionCubit extends Cubit<Set<String>> {
  ChapterAccordionCubit() : super(const {});

  void toggle(String chapterId) {
    final next = Set<String>.from(state);
    if (!next.remove(chapterId)) next.add(chapterId);
    emit(next);
  }
}
