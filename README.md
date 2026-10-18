# BreakLog

A personal bboy move log for Android. Log every toprock, footwork, power,
freeze, and combo you are working on, rate difficulty, keep drill notes,
attach reference videos, and track progress over time.

Everything stays on the device: local storage only, no account, no server.

## Stack

- Flutter (pinned 3.41.0 in CI), Material 3, dark theme
- `provider` for state, `shared_preferences` for JSON persistence
- `phosphor_flutter` icons, `google_fonts` (Barlow Condensed display, Inter body)
- `package_info_plus` + `http` for the GitHub releases update check
- `url_launcher` for video references and release links

## Layout

```
lib/
  main.dart                app entry, provider wiring
  config.dart              GitHub coordinates for updates
  theme/app_theme.dart     black + red dark theme
  models/move.dart         BboyMove + MoveCategory
  services/
    move_repository.dart   move list + persistence
    version_checker.dart   GitHub releases feed parsing
  state/
    app_state.dart         composition root
    update_notifier.dart   update availability
  screens/                 feature folders (library, detail, edit, stats, updates, settings, about)
  widgets/                 move card, empty state
```

## CI and releases

`.github/workflows/build.yml` runs on pushes, PRs, and tags:

1. `flutter analyze --no-fatal-infos` and `flutter test`
2. `flutter build apk --release --split-per-abi` (arm64 only)
3. Pushes to `main` publish a rolling `beta` pre-release as
   `BreakLog-<version>-beta.apk`
4. Tags `v*` publish a stable `BreakLog-<version>-arm64.apk`

Release signing comes from secrets: `ANDROID_KEYSTORE_B64` (base64 PKCS12
keystore), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`. Without them the build falls back to debug signing.

The app checks the releases feed for newer versions. Stable channel by
default; the beta channel can be opted into from Settings.

## Build locally

```sh
flutter pub get
flutter run
```

Release builds sign with `android/key.properties` when present, otherwise
fall back to debug keys.
