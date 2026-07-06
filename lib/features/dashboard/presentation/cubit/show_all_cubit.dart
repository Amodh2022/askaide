import 'package:flutter_bloc/flutter_bloc.dart';

/// Show-all/show-less toggle shared by the achievements card variants.
class ShowAllCubit extends Cubit<bool> {
  ShowAllCubit() : super(false);

  void toggle() => emit(!state);
}
