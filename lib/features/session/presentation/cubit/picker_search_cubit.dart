import 'package:flutter_bloc/flutter_bloc.dart';

/// Search query for the bottom-sheet option picker used by the study config
/// dropdowns. One instance per sheet open.
class PickerSearchCubit extends Cubit<String> {
  PickerSearchCubit() : super('');

  void setQuery(String value) => emit(value);
}
