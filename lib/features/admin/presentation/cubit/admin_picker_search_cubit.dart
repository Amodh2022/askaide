import 'package:flutter_bloc/flutter_bloc.dart';

/// Search query for the admin bottom-sheet record picker (`_PickerSheet`).
/// One instance per sheet open.
class AdminPickerSearchCubit extends Cubit<String> {
  AdminPickerSearchCubit() : super('');

  void setQuery(String value) => emit(value);
}
