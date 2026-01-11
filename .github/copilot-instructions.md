## Quick summary

This is a Flutter (mobile + desktop) chat application using Firebase as its backend. Key areas:

- Entry: `lib/main.dart` — initializes Firebase and `NotificationService` and selects the initial screen based on `FirebaseAuth` state.
- UI layer: `lib/view/` — screens are named `*_screen.dart` (e.g. `auth_screen.dart`, `home_screen.dart`).
- Presentation layer: `lib/presenter/` — MVP-style presenters (e.g. `AppPresenter`) drive UI logic and call `AppView` to update the UI.
- Data & models: `lib/data/` and `lib/model/` — data access and DTOs; services in `lib/services/` wrap platform and Firebase integrations.
- Utilities: `lib/utils/` — app-wide helpers and theming (`AppTheme`, `ThemeModeType`).

## Architecture notes (what to know first)

- The app follows a lightweight MVP-ish pattern: presenters (files in `lib/presenter/`) hold business logic and call methods on a small `View` interface (see `lib/view/app_view.dart` with `void updateView()`). Use presenters for orchestrating flows rather than putting logic in widgets.
- Main data/integration points are Firebase products configured via packages in `pubspec.yaml` (auth, firestore, storage, messaging). See `pubspec.yaml` for exact versions. Android and iOS platform files include `google-services.json` / iOS Firebase config in the native folders.
- Notifications are initialized early in `main()` via `NotificationService().initialize()` (see `lib/services/notification_service.dart`). If changing notification startup, update `main.dart` accordingly.

## Developer workflows (discoverable commands)

- Install dependencies: `flutter pub get` (run from repo root).
- Static analysis: `flutter analyze` (project uses `flutter_lints` declared in `pubspec.yaml`).
- Run app: `flutter run` (specify device with `-d` if needed, e.g. `-d windows` or a mobile emulator).
- Tests: `flutter test` (project contains `flutter_test` in dev_dependencies; add tests near the code they exercise).

Note: The repo includes native android/iOS folders — building on-device or for iOS may require platform-specific setup (Xcode, signing, GoogleService-Info.plist).

## Project-specific conventions

- Naming: presenters are `*_presenter.dart`, views/screens are `*_screen.dart`. Keep presenters small and focused on UI orchestration.
- Single small View interface per feature: pages implement a minimal interface (e.g. `AppView`) and presenters call `updateView()` after state changes; prefer immutable models and let the view read presenter state.
- Theme control: `ThemeModeType` enum in `lib/utils/app_theme.dart` is used in `MainAppState` to pick `themeMode`. If adding theme sources, update that enum and `MainAppState._getThemeMode`.

## Integration & external dependencies (where to look)

- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging` — see `pubspec.yaml` and native platform files under `android/` and `ios/`.
- Media & files: `image_picker`, `file_picker`, `record`, `audioplayers` — these are used for attachments and voice; look in `lib/services/` and `lib/view/` screens that present upload/record UIs.
- Encryption/crypto: `encrypt` and `pointycastle` are included — search `lib/` for usages if changing message storage format.

## Small examples (copyable patterns)

- Initialize services in `main()` (already present):

  - Firebase: `await Firebase.initializeApp();`
  - Notifications: `await NotificationService().initialize();`

- Presenter -> View interaction (pattern to follow):

  - Presenter calls `_view.updateView();` after state changes. See `lib/presenter/app_presenter.dart` and `lib/view/app_view.dart`.

## Where to change common behaviors

- To change auth flow: inspect `lib/main.dart` (StreamBuilder on `FirebaseAuth.instance.authStateChanges()`), `lib/view/auth_screen.dart`, and presenters in `lib/presenter/auth_presenter.dart`.
- To modify notification logic: edit `lib/services/notification_service.dart` and the initialization in `lib/main.dart`.
- To add new backend calls: add a new service under `lib/services/`, then call it from a presenter.

## What an AI agent should not change without human review

- Native platform files (AndroidManifest, Info.plist, `google-services.json`, signing configs).
- Pubspec dependency upgrades — propose versions in a PR and run `flutter pub get` + `flutter analyze`.

## Useful files to inspect first

- `lib/main.dart` — app entry and high-level wiring
- `pubspec.yaml` — dependencies and versions
- `lib/presenter/` — all presenters; shows app orchestration style
- `lib/view/` — UI screens and widget conventions
- `lib/services/` — Firebase and platform wrappers
- `lib/utils/app_theme.dart` — theming and `ThemeModeType`

## Final notes

Keep edits small and focused. When adding features, prefer: new service (in `lib/services/`) + presenter + view screen. Run `flutter analyze` and `flutter test` locally before merging.

If anything in these instructions is unclear or you'd like more detail (e.g., common state fields on presenters or where to place unit tests), tell me which area to expand and I'll update this file.
