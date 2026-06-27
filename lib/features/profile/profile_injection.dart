import 'package:get_it/get_it.dart';

import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/usecases/get_user_details.dart';
import 'domain/usecases/profile_actions.dart';
import 'domain/usecases/update_profile.dart';
import 'presentation/cubit/profile_cubit.dart';

void registerProfile(GetIt sl) {
  sl
    ..registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetUserDetails(sl()))
    ..registerLazySingleton(() => UpdateProfile(sl()))
    ..registerLazySingleton(() => ChangePassword(sl()))
    ..registerLazySingleton(() => UpdateDisplayPicture(sl()))
    ..registerLazySingleton(() => DeleteProfilePhoto(sl()))
    ..registerLazySingleton(() => DeleteProfile(sl()))
    ..registerLazySingleton<ProfileCubit>(
      () => ProfileCubit(
        getUserDetails: sl(),
        updateProfile: sl(),
        changePassword: sl(),
      ),
    );
}
