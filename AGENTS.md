# Agents

## Dev Commands

```sh
flutter analyze      # lint + static analysis
flutter test         # run tests
flutter run          # run on connected device/emulator
flutter build apk    # build Android APK
```

## Architecture

- **Entry point**: `lib/main.dart` → `lib/app/app.dart` (`ForumBrinApp`)
- **State Management**: `flutter_bloc` (Cubit pattern)
- **Core services**:
  - `lib/core/network/api_client.dart` → `http://forum-brin.test/api`
  - `lib/core/services/logger/` → logging service
  - `lib/core/services/layout/` → layout service
- **Features** (`lib/features/`):
  - `auth/`: `cubits/`, `models/`, `screens/`, `services/`
  - `dashboard/`: `screens/`, `widgets/`
  - `questions/`: `cubits/`, `models/`, `screens/`, `services/`, `widgets/`
- **Assets**: `assets/images/logo_brin.png`

## Testing

- Single test file: `test/widget_test.dart`
- Run: `flutter test test/widget_test.dart`

## Notes

- SDK constraint: `>=3.2.6 <4.0.0`
- Uses `http` package; Bearer token auth via `ApiClient._buildHeaders()`
- App title: `BOSDM Connect`; Primary color: `Color(0xFFC62828)`
- `.metadata` marks `lib/main.dart` as unmanaged (don't run `flutter migrate`)
