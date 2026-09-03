# MineTrack Mobile

Native Android application for MineTrack, built with Flutter and powered by Supabase.

## Status

Early development — production architecture and project foundation.

## Purpose

MineTrack Mobile brings the core MineTrack permit-management experience to Android while sharing the existing Supabase backend with the web application.

### Initial product scope

- Authentication and session management
- Dashboard
- New Permit Registration
- Permit Registry
- Permit details and lifecycle actions
- Geospatial/map view
- Notifications
- Profile
- Settings
- Role-aware user management

## Technology

- Flutter / Dart
- Android
- Supabase: PostgreSQL, Auth, Storage, Realtime and Edge Functions
- Android Studio for native Android development and release

## Architecture

```text
UI / Screens
    ↓
ViewModels / Controllers
    ↓
Repositories
    ↓
Supabase Services
    ↓
PostgreSQL / Auth / Storage / Realtime / Edge Functions
```

The Flutter application is a native client. The existing MineTrack web application remains the reference for business behavior and existing backend integrations; mobile presentation and interaction patterns are implemented natively rather than attempting to reuse web UI code.

## Project structure

```text
lib/
├── core/                  # App-wide configuration, routing, theme, errors and services
├── models/                # Shared domain/data models
├── repositories/          # Repository contracts and shared data access
├── features/              # Feature-specific data, logic and presentation
│   ├── auth/
│   ├── dashboard/
│   ├── permits/
│   ├── map/
│   ├── notifications/
│   ├── profile/
│   └── settings/
└── shared/                # Reusable widgets and layouts

assets/                    # Images, icons and fonts
android/                   # Native Android project
integration_test/          # End-to-end tests
test/                      # Unit and widget tests
.github/workflows/         # CI
```

## Requirements

- Flutter SDK
- Dart SDK (managed by Flutter)
- Android Studio
- Android SDK and an Android emulator or physical Android device

Verify the local setup:

```bash
flutter doctor
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Environment configuration

Backend configuration must never contain privileged Supabase credentials in source control.

Copy the example configuration when environment loading is configured:

```bash
cp .env.example .env
```

The client may use the Supabase project URL and publishable/anon key. **Never ship a Supabase service-role key inside the Flutter application.** Authorization and privileged operations must be enforced server-side with RLS and, where necessary, Edge Functions.

## Security principles

- Supabase Row Level Security is the source of truth for database authorization.
- Client-side role checks are for UX only, never security.
- Service-role credentials remain server-side.
- Sensitive configuration is never committed.
- Authentication state is handled centrally.
- Destructive and privileged operations require backend authorization.

## Testing

Production features should include appropriate unit, widget and/or integration coverage.

```bash
flutter format --set-exit-if-changed .
flutter analyze
flutter test
```

## Production Android release

The Play Store release artifact is an Android App Bundle:

```bash
flutter build appbundle --release
```

Release signing, package identity, versioning, R8 configuration where required, and Play Console deployment are production concerns and must be configured before release.

## Relationship to the web application

MineTrack Mobile is a separate Flutter application. It does not replace the existing web application. Both clients use the same backend contract and should preserve the same underlying business rules, permissions and data semantics.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development standards, branch conventions, testing requirements and pull-request expectations.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Copyright © 2026 Hassan Agyemang Boakye. All rights reserved.

See [LICENSE](LICENSE).
