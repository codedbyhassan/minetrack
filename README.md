# MineTrack Mobile

Native Android application for MineTrack, built with Flutter and powered by Supabase.

## Status

Active development — the Android project, release structure, authentication, permit lifecycle, map handoff, expiry alerts and CI foundation are in place.

## Purpose

MineTrack Mobile brings the core MineTrack permit-management experience to Android while sharing the existing Supabase backend with the web application.

### Product scope

- Authentication and session management
- Dashboard
- New Permit Registration
- Permit Registry
- Permit details and lifecycle actions
- Permit renewal workflow
- Permit locations with Google Maps handoff
- Expiry alerts / notifications
- Profile
- Settings
- Role-aware user management

## Technology

- Flutter / Dart
- Android
- Supabase: PostgreSQL, Auth, Storage, Realtime and Edge Functions
- Android Studio for native Android development and release

## Android identity

- Application ID: `com.codedbyhassan.minetrack`
- Display name: `MineTrack`
- Minimum Android SDK: 21
- Release artifact: Android App Bundle (`.aab`)

The application ID is part of the permanent Play Store identity. Do not change it after publishing.

## Architecture

```text
UI / Screens
    ↓
Controllers / Providers
    ↓
Feature Repositories
    ↓
Supabase Service
    ↓
PostgreSQL / Auth / Storage / Realtime / Edge Functions
```

The Flutter application is a native client. The existing MineTrack web application remains the reference for business behavior and existing backend integrations; mobile presentation and interaction patterns are implemented natively rather than attempting to reuse web UI code.

## Project structure

```text
lib/
├── core/
│   ├── auth/
│   ├── config/
│   ├── routing/
│   ├── services/
│   ├── shell/
│   └── theme/
├── models/
└── features/
    ├── auth/
    ├── dashboard/
    ├── map/
    ├── notifications/
    ├── permits/
    ├── profile/
    └── settings/

android/                   # Native Android project
supabase/migrations/       # Exact MineTrack database migrations
.github/workflows/         # CI
test/                      # Unit and widget tests
```

## Requirements

- Flutter SDK 3.35+
- Dart SDK (managed by Flutter)
- Android Studio
- Android SDK
- Android emulator or physical Android device

Verify the local setup:

```bash
flutter doctor
```

## Development

Install dependencies and validate the project:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run
```

## Supabase configuration

The app reads the Supabase project URL and publishable/anon key at compile time through Dart defines. No Supabase credentials are hardcoded in the repository.

Run locally with:

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="YOUR_PUBLISHABLE_OR_ANON_KEY"
```

For Android Studio, add the same two values to the Run/Debug configuration under **Additional run args**.

**Never ship a Supabase service-role key inside the Flutter application.** Authorization and privileged operations must be enforced server-side with RLS and, where necessary, Edge Functions.

## Database contract

The mobile client intentionally uses the existing MineTrack Supabase schema. The migrations in `supabase/migrations/` are kept as the source-of-truth database contract; mobile code must use the exact column names and relationships defined there.

In particular, the organization-scoped permit model uses `organization_id`, and permit file numbers are unique within an organization rather than globally.

## Release signing

Release signing is deliberately separated from source control. Never commit a keystore or `android/key.properties`.

Start from the checked-in template:

```bash
cp android/key.properties.example android/key.properties
```

Create or obtain the production upload keystore, then update `android/key.properties` with its real values.

Build the Play Store artifact:

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="YOUR_PUBLISHABLE_OR_ANON_KEY"
```

The release build is configured for code shrinking/resource shrinking. Test the signed release build on a physical Android device before uploading it to Google Play Console.

## Android Studio

Open the repository root in Android Studio. Allow Android Studio to detect the Flutter project and install any missing SDK components. Select an emulator or connected Android device and run the `main.dart` configuration.

For a production release, configure the signing key locally and use **Build → Flutter → Build App Bundle** or the command-line build shown above.

## Security principles

- Supabase Row Level Security is the source of truth for database authorization.
- Client-side role checks are for UX only, never security.
- Service-role credentials remain server-side.
- Sensitive configuration is never committed.
- Authentication state is handled centrally.
- Destructive and privileged operations require backend authorization.

## Testing and CI

GitHub Actions runs dependency installation, formatting checks, static analysis, tests and an Android debug APK build on pushes and pull requests targeting `main`.

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Production release signing is intentionally not performed by the public CI workflow; signing credentials should be supplied through a protected release pipeline when automated Play Store publishing is introduced.

## Relationship to the web application

MineTrack Mobile is a separate Flutter application. It does not replace the existing web application. Both clients use the same backend contract and should preserve the same underlying business rules, permissions and data semantics.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development standards, branch conventions, testing requirements and pull-request expectations.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Copyright © 2026 Hassan Agyemang Boakye. All rights reserved.

See [LICENSE](LICENSE).
