# AGENTS.md — Victoria Fabrics

Flutter app (`fabric_haven` package) for a Nigerian fabric store. Builds **two APKs**
from one codebase.

| App | Entry point | Router |
|---|---|---|
| Customer | `lib/main.dart` | `lib/presentation/router/app_router.dart` |
| Admin | `lib/main_admin.dart` | `lib/admin/router/admin_router.dart` |

## Build & test

The repo needs **JDK 17** (Gradle 8.3 + AGP are incompatible with JDK 21 — `jlink`
fails during `JdkImageTransform`). Android SDK and JDK are installed under
`/workspace/tooling/`.

```bash
export ANDROID_HOME=/workspace/tooling/android-sdk
export JAVA_HOME=/workspace/tooling/jdk17
export PATH=/workspace/tooling/flutter/bin:$JAVA_HOME/bin:$PATH

flutter test
flutter analyze                                        # clean: 0 issues
flutter build apk --debug --target lib/main.dart
flutter build apk --debug --target lib/main_admin.dart
```

CI (`.github/workflows/ci.yml`) runs bare `flutter analyze`, which exits non-zero on
`info` lints, so the "Lint & Analyze" job has been red on every commit for a long time.
"Build APKs" succeeds.

## Architecture

- State: Riverpod. Navigation: GoRouter.
- Data: `FirestoreService` (singleton) is the only Firestore gateway.
- Products + orders + tickets = real Firestore. Cart is in-memory Riverpod state.

## Known gaps (updated 2026-09-16)

**Blocker — no Firestore database exists.** Project `victoria-fabrics` still returns
`NOT_FOUND: The database (default) does not exist` for
`firestore.googleapis.com/v1/projects/victoria-fabrics/databases/(default)`.
`firebase.json`, `firestore.rules` and `firestore.indexes.json` are now committed, so the
database can be provisioned with `firebase deploy --only firestore` (or from the console).
Until it exists, every data-backed screen fails at runtime. This is an environment step,
not a code gap.

**Firestore rules are in place** (`firestore.rules`). Admin is identified by a `role` of
`admin`/`staff` on `users/{uid}` (with a custom-claim shortcut). Writing the catalogue or
changing an order status requires that role, so an admin account must exist:
1. Create the user in Firebase Auth.
2. Add `users/{uid}` with `role: "admin"`.

**Android signing.** `google-services.json` registers an OAuth client for a different
debug keystore SHA-1 (`a029a10f…`) than the one in this environment (`18bbb7f8…`), so
Google sign-in returns a developer-error dialog here. The customer app signs in with a
Firebase Auth user; add the local keystore SHA-1 in the Firebase console to test Google
sign-in on this machine. Release builds are still signed with the debug key — configure a
real upload key before publishing.

**`lib/firebase_options.dart` covers Android only.** iOS/web need `flutterfire configure`.

**Catalogue seeding is an explicit admin action.** `seedProductsIfEmpty()` now runs from
the admin Products screen overflow menu rather than during startup, because the rules
reject unauthenticated writes and a network round trip does not belong on the launch path.

**Payments are manual bank transfer** (`PaymentConstants`) by design — order is placed as
`pending` and confirmed by the admin once the transfer lands. Not a bug.

## Verified working

`flutter analyze` is clean (0 issues) and `flutter test` passes (11 tests, including
Firestore serialization round-trips). Both APKs build. Real Firestore-backed flows:
customer auth (Google + Firebase Auth session), catalogue browsing, search, cart,
checkout, order history, support tickets, and the admin auth, dashboard, products,
categories, orders, order detail, tickets and analytics screens.
