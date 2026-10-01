# Victoria Fabrics — working notes

Flutter app, package name `fabric_haven`. One codebase, two installable
Android apps: customer (`lib/main.dart`, flavor `customer`) and staff
(`lib/main_admin.dart`, flavor `admin`). Each flavor has its own
`applicationId`, so both install side by side.

## Commands

```bash
flutter pub get
flutter analyze            # must be clean; CI runs --fatal-infos
flutter test               # full suite
dart run flutter_native_splash:create   # regenerate native splash after
                                        # changing the splash asset or colors
flutter build apk --debug --flavor customer --target lib/main.dart
flutter build apk --debug --flavor admin --target lib/main_admin.dart
```

CI (`.github/workflows/ci.yml`) runs lint, tests, a Cloud Functions
type-check, and a debug/release build of *both* flavors. A flavorless
`flutter build apk` fails once flavors exist — always pass `--flavor`.

## Toolchain

Flutter **3.47.5** (Dart 3.13), pinned in both workflows. The Firebase 4.x /
`image_picker` 1.2.x / `flutter_native_splash` 2.4.8 bumps all need Dart
≥ 3.10, so the older 3.24 pin cannot resolve them — do not downgrade it back.

Android side (all required by Flutter 3.47):

| Piece | Version | Why |
| --- | --- | --- |
| Gradle | 9.3.1 | Flutter 3.47 refuses anything below 8.14 |
| AGP | 9.1.0 | Matches Flutter 3.47's template; older AGP fails the DSL check |
| Kotlin | 2.4.0 | Matches the template |
| compileSdk | 36 | `image_picker_android` / `androidx.activity` 1.13 need API 36 |
| NDK | 28.2.13676358 | Flutter 3.47 default (`flutter.ndkVersion`) |

`android/gradle.properties` sets `android.newDsl=false` and
`android.builtInKotlin=false` so AGP 9 keeps using the legacy DSL that
`android/app/build.gradle` is written in; flavor `resValue` also needs
`buildFeatures { resValues = true }`. `coreLibraryDesugaring` is on for
`flutter_local_notifications`.

Theme/API notes for this SDK: use `Color.withValues(alpha:)` (not
`withOpacity`), `CardThemeData` (not `CardTheme`), and
`DropdownButtonFormField(initialValue:)` (not `value:`). CI runs
`flutter analyze --fatal-infos`, so any new deprecation fails the build.

## Architecture

Layered: `domain/` (entities, pure) → `data/` (repositories, mappers,
datasources) → `presentation/` and `admin/` (Riverpod + screens/widgets).
`services/` holds the Firebase-facing clients.

Repositories return `Result<T>` and wrap calls in `guard()`; screens never
touch `FirebaseFirestore` directly. Providers are in
`core/providers/repository_providers.dart` — override them in tests rather
than hitting Firebase.

Pure mappers in `data/mappers/` (`buildOrderDocument`, `buildOrderLineItem`)
exist specifically so order math is unit-testable without Firebase. Keep
pricing logic there, not in widgets or services.

## Free tier constraints (no billing account)

The project runs on Firebase's Spark plan, so Cloud Functions and Cloud
Storage are not reliably available. Both order placement and product image
upload therefore have fallbacks:

- `FirestoreService.placeOrder` calls the `placeOrder` callable and falls
  back to a client-side Firestore transaction. `firestore.rules` re-derives
  every price server-side for that path — never trust a client-supplied
  price or total.
- `StorageService.uploadProductImage` falls back to `encodeInline()`, which
  stores a downscaled JPEG as a `data:` URI inside the product document.
  `ProductImage` renders assets, remote URLs and data URIs. The encoder is a
  pure function; test it directly.

`firestore.rules`, `storage.rules` and `firestore.indexes.json` are
deny-by-default. The order create rule pins an exact field set and caps line
count, name, phone and total. `kMaxOrderLines` in `order_document.dart`
mirrors the rules' 10-line ceiling — change both together.

## Conventions

- `AppLogger` for all logging, tagged by area (`admin_products`, `firestore`).
- Errors surface through `ErrorMapper`; user-facing copy stays plain.
- Widget tests use `ProviderScope` overrides, and layout tests pump at
  320/390/1024 pt widths and assert `tester.takeException()` is null, which
  catches RenderFlex overflows.
- `android/app/google-services.json` is tracked (Firebase config, not a
  secret). Signing keys, `key.properties` and service-account JSON are
  gitignored — keep it that way.

## Gotchas

- `flutter_native_splash` regenerates `android/app/src/main/res/values/colors.xml`;
  `splash_background` must survive that (it is in `pubspec.yaml` too).
- The admin launcher icon is a flavor override under
  `android/app/src/admin/res`; regenerate with `tool/generate_icons.py`.
- CI status checks and a PR-only branch rule are configured on `main`.
