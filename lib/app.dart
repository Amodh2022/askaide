import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/sound/sound_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/session/presentation/bloc/session_bloc.dart';

/// Root widget. Provides the app-global blocs from the service locator, wires
/// the router once, and rebuilds the [MaterialApp] only when the [ThemeMode]
/// changes. A [BlocListener] keeps the profile in sync with auth status.
class AskAideApp extends StatefulWidget {
  const AskAideApp({super.key});

  @override
  State<AskAideApp> createState() => _AskAideAppState();
}

class _AskAideAppState extends State<AskAideApp> {
  late final AuthBloc _authBloc = sl<AuthBloc>();
  late final ProfileCubit _profileCubit = sl<ProfileCubit>();
  late final AppRouter _appRouter =
      AppRouter(authBloc: _authBloc, profileCubit: _profileCubit);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<SoundCubit>.value(value: sl<SoundCubit>()),
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ProfileCubit>.value(value: _profileCubit),
        BlocProvider<SessionBloc>.value(value: sl<SessionBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            _profileCubit.loadUser();
          } else if (state.status == AuthStatus.unauthenticated) {
            _profileCubit.clear();
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              routerConfig: _appRouter.router,
            );
          },
        ),
      ),
    );
  }
}
