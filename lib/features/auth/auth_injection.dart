import 'package:get_it/get_it.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/auth_usecases.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/cubit/forgot_password_form_cubit.dart';
import 'presentation/cubit/login_form_cubit.dart';
import 'presentation/cubit/signup_form_cubit.dart';
import 'presentation/cubit/update_password_form_cubit.dart';

void registerAuth(GetIt sl) {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remote: sl(), storage: sl()))
    ..registerLazySingleton(() => Login(sl()))
    ..registerLazySingleton(() => LoginWithGoogle(sl()))
    ..registerLazySingleton(() => SendOtp(sl()))
    ..registerLazySingleton(() => Signup(sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerLazySingleton(() => ResetPassword(sl()))
    ..registerLazySingleton(() => Logout(sl()))
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        repository: sl(),
        login: sl(),
        loginWithGoogle: sl(),
        sendOtp: sl(),
        signup: sl(),
        requestPasswordReset: sl(),
        resetPassword: sl(),
        logout: sl(),
      ),
    )
    // ---- Page-scoped form cubits (fresh instance per page mount) --------
    ..registerFactory<LoginFormCubit>(() => LoginFormCubit(sl<AuthBloc>()))
    ..registerFactory<SignupFormCubit>(() => SignupFormCubit(sl<AuthBloc>()))
    ..registerFactory<ForgotPasswordFormCubit>(
        () => ForgotPasswordFormCubit(sl<AuthBloc>()))
    ..registerFactory<UpdatePasswordFormCubit>(
        () => UpdatePasswordFormCubit(sl<AuthBloc>()));
}
