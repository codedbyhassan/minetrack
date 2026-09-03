# Contributing to MineTrack Mobile

Thank you for contributing to MineTrack Mobile. This project is intended to be production software, so changes should favor correctness, maintainability, security and consistency over shortcuts.

## Development principles

- Read the existing implementation before changing behavior.
- Reuse established architecture and backend contracts where possible.
- Keep business logic out of widgets.
- Keep Supabase authorization enforced by the backend and RLS.
- Do not expose service-role credentials in the Flutter client.
- Prefer small, focused changes over broad rewrites.
- Preserve accessibility, loading, error and empty states.
- Avoid introducing dependencies without a clear reason.

## Branches

Use descriptive branch names:

```text
feature/permit-registration
feature/permit-map
fix/auth-session
fix/permit-filter
refactor/repository-layer
chore/ci
```

Do not develop directly on `main` unless the change is an explicitly approved maintenance operation.

## Commits

Use concise Conventional Commit-style messages:

```text
feat: add permit registration flow
fix: handle expired auth session
refactor: separate permit repository
chore: update flutter workflow
docs: document release process
test: add permit repository coverage
```

## Code quality

Before opening a pull request, run:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

If integration tests are affected, also run:

```bash
flutter test integration_test
```

New production behavior should have appropriate tests.

## Architecture rules

Features should follow the project's separation of concerns:

```text
Presentation
    ↓
ViewModel / Controller
    ↓
Repository
    ↓
Supabase / Service
```

Widgets should primarily render state and dispatch user actions. Database access should not be scattered across screens.

Shared UI belongs under `lib/shared/`; app-wide infrastructure belongs under `lib/core/`; feature-specific behavior belongs inside its feature directory.

## Supabase and security

- Never commit `.env` files or secrets.
- Never put the Supabase service-role key in Flutter code.
- Treat client-side permission checks as UX only.
- Validate authorization through Supabase RLS and server-side functions.
- Do not bypass existing database policies to make a feature work.

## Pull requests

A pull request should explain:

1. What changed.
2. Why it changed.
3. Any database, authentication or backend implications.
4. How it was tested.
5. Any screenshots or recordings needed to review UI changes.

PRs should be focused and should not mix unrelated refactors with feature work unless the refactor is required for the feature.

## UI and UX

MineTrack Mobile is a native Android application. Interfaces should be designed for touch first:

- Comfortable tap targets.
- Clear hierarchy and readable typography.
- Responsive layouts across Android screen sizes.
- Explicit loading, error and empty states.
- Appropriate dark/light theme behavior.
- Smooth but purposeful transitions.
- Accessible labels and semantics where appropriate.

## Release discipline

Production builds must use the release configuration and signed Android App Bundle process. Never test production signing credentials in source control.

```bash
flutter build appbundle --release
```
