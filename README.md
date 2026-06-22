# AskAide — Flutter (mobile + web)

A Flutter replica of the AskAide EdTech platform. Built with **clean
architecture** + **flutter_bloc**. This repo currently implements **build steps
1–3**: the design system, the adaptive router/shell, and the data/state layer.

## Architecture

Feature-first clean architecture. Each feature has three layers:

```
lib/
  core/                     # cross-cutting: theme, network, storage, di, router, shell
    theme/                  # "Quiet Scholar" design system (single source of truth)
    network/                # Dio client + interceptors + endpoints
    storage/                # secure storage (JWT) + Hive/SharedPreferences
    error/                  # Failure / Exception types
    usecases/               # UseCase base contract
    di/                     # get_it service locator
    router/                 # go_router + guards + refresh stream
    presentation/shell/     # adaptive sidebar / bottom-nav / navbar / FABs
  features/
    auth/    | profile/ | session/
      domain/      # entities, repository contracts, use cases  (pure Dart)
      data/        # DTO models, datasources, repository impls   (maps to domain)
      presentation/# blocs / cubits                              (UI state)
```

**Patterns:** Repository (domain abstraction + data impl) · Use Case /
interactor · DI service locator · BLoC/Cubit · `Either<Failure, T>` functional
error handling · Adapter (Dio interceptors, `GoRouterRefreshStream`).

The dependency rule points inward: `presentation → domain ← data`. Domain knows
nothing about Flutter, Dio, or JSON.

## Setup

This project is delivered as source. Generate the platform folders and the
freezed/json code, then run:

```bash
# 1. From the project root, create the native platform scaffolding
#    (does NOT overwrite lib/ or pubspec.yaml):
flutter create . --platforms=android,ios,web --org ai.askaide

# 2. Fetch packages
flutter pub get

# 3. Generate freezed / json_serializable code (*.freezed.dart, *.g.dart)
dart run build_runner build --delete-conflicting-outputs

# 4. Run
flutter run -d chrome        # web
flutter run                   # mobile device/emulator
```

### Environment

The API base URL is a compile-time define (defaults to the hosted backend):

```bash
flutter run --dart-define=API_BASE_URL=https://askaideaibackend.onrender.com/api/v1
```

## Design system — "Quiet Scholar"

`AskAideColors` is a `ThemeExtension` holding every token for both light and
dark. `AppTheme.light()` / `AppTheme.dark()` are the only consumers; widgets
read colors via `context.colors.accent`, so swapping `ThemeMode` "just works".
Typography (Fraunces / Inter Tight / JetBrains Mono) lives in `AppTypography`.

## What's implemented (steps 1–3)

- **Theme**: full token set, light + dark `ThemeData`, typography scale, shape
  & shadow tokens, `ThemeCubit` (persisted toggle).
- **Routing/shell**: every route from the spec, auth + role-gated redirect
  guards, `ShellRoute` with an adaptive sidebar (desktop ≥768px) / bottom-nav +
  drawer (mobile), public navbar, WhatsApp FAB (public), floating AI assistant.
- **Data/state**: Dio client (auth + error interceptors, 30s timeout),
  `Endpoints`, secure + local storage, `auth` / `profile` / `session` features
  end-to-end (entities → repositories → use cases → blocs), including the study
  session machine with **batched fetch/submit + offline answer queue + sync on
  reconnect**.

Screens render via a themed `PlaceholderPage` until built in steps 4–6. See
`SCREEN_SPECS.md` for the per-screen layouts.

## Next (steps 4–6)

Auth screens · core study flow UI · dashboards · quizzes · paper generator ·
landing/marketing pages.
