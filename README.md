# Victoria Fabrics

A Flutter mobile app for Victoria Fabrics — a Nigerian fabric store selling Ankara, Lace, Cotton, Silk, Voile, and Chiffon fabrics.

## Apps

This repo builds **two separate APKs** from a single codebase:

| App | Entry point | Purpose |
|-----|------------|---------|
| **Customer App** | `lib/main.dart` | Browse products, add to cart, place orders |
| **Admin App** | `lib/main_admin.dart` | Manage products, orders, categories, analytics |

## Download APKs

After each push to `main`, GitHub Actions builds both apps automatically.

1. Go to the [**Actions tab**](../../actions) on GitHub
2. Click the latest **"Build APKs"** workflow run
3. Scroll to **Artifacts** at the bottom
4. Download:
   - `victoria-fabrics-admin-release` — Admin app (production)
   - `victoria-fabrics-customer-release` — Customer app (production)
   - Debug builds are also available

## Admin Access

Admin accounts are provisioned server-side in Firebase Authentication and
granted a role in the `admins` Firestore collection. There are **no shared
credentials in this repository** — never commit admin logins to source.

## Tech Stack

- Flutter 3.24 / Dart 3.5
- Firebase (Auth + Firestore)
- Riverpod (state management)
- GoRouter (navigation)
- Cached Network Image

## Firebase

The `google-services.json` is included at `android/app/google-services.json`
for the Firebase project `victoria-fabrics`. Treat this file as environment
configuration: in a multi-environment setup, inject it at build time rather
than committing per-project copies.

Google sign-in also requires provider and SHA-1 configuration in the Firebase
console. See [`docs/google-sign-in-setup.md`](docs/google-sign-in-setup.md) for
the two failure messages it can produce and how to resolve them.

### Security rules

`firestore.rules` and `storage.rules` are deny-by-default and enforce
authorization server-side:

- The catalogue (products and categories) is world-readable; only staff may
  create/delete products or manage categories. A signed-in customer may only
  *decrease* `stockCount`/`inStock` when placing an order through the
  transaction fallback.
- Orders are validated server-side. The rules require `status == 'pending'`, a
  server timestamp, `userId == request.auth.uid`, and — critically — that
  **every line item's price and line total match the authoritative product
  document**. A client therefore cannot dictate its own price. Clients may
  only read their own orders; staff may advance status; nobody may rewrite or
  delete an order.
- Tickets may be opened by anyone but only advanced by staff.
- Admin roles come from a `role` custom claim or the `admins/{uid}` document,
  never from client input.
- `_meta/*` holds write-once seeding markers so a first launch cannot clobber
  existing catalogue data.

Deploy them with the Firebase CLI:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

> On first launch against an empty database the app seeds the bundled default
> products and categories (best-effort, idempotent). Those writes require the
> staff role; if you prefer to seed server-side, use the Admin SDK and the
> `_meta` marker is respected either way.

### Order integrity: two enforcement paths

Order money/stock integrity is enforced in **two** places, so the app is
secure whether or not you are on a paid plan:

1. **`placeOrder` Cloud Function** (preferred). Re-derives prices, stock and
   total with the Admin SDK. Requires the **Blaze** plan — Cloud Functions
   cannot run on the free Spark plan.
2. **Security-rules validation** (free-tier fallback). When functions are
   unavailable the client places the order in a Firestore transaction and the
   rules independently verify each line against the product document. The
   rules engine allows 10 document lookups per request, so an order is capped
   at 10 distinct lines (enforced in the cart UI).

The client tries the function first and falls back only on a
*configuration* error (function not deployed/unreachable). A genuine
rejection from the server — stale total, out of stock, bad payload — is
surfaced to the user and never silently retried on the weaker path.

> The fallback is materially stronger than the original client-trusted code,
> but the Cloud Function remains the strongest option: it is the only path
> that also enforces per-product stock atomically. Deploy it when you can —
> see [Cloud Functions](#cloud-functions) below.

## Cloud Functions

`functions/` holds the trusted server-side logic (TypeScript, Node 20). It is
the strongest place order money/stock integrity is enforced.

| Function | Purpose |
| --- | --- |
| `placeOrder` | Authoritative order placement: re-reads product prices, recomputes the total, decrements stock and writes a pinned `pending` order. |
| `setAdminRole` | Super-admin-only: grants/updates an admin role (custom claim + `admins/{uid}` roster). |
| `removeAdminRole` | Super-admin-only: revokes an admin role. |

```bash
cd functions
npm install
npm run lint          # type-check
firebase deploy --only functions
```

The client calls `placeOrder` through `cloud_functions` and falls back to the
rules-validated transaction when it is not deployed; the Firestore rules block
any direct client write that does not match the product catalogue.

## Project Structure

```
lib/
├── main.dart              # Customer app entry point
├── main_admin.dart        # Admin app entry point
├── core/                  # Cross-cutting foundations
│   ├── config/            # Environment / app configuration
│   ├── constants/         # App-wide constants & enums
│   ├── error/             # Failure types, Result type, error mapper
│   ├── logging/           # Structured AppLogger
│   ├── providers/         # Auth + repository providers
│   ├── theme/             # App theme
│   └── validation/        # Reusable form validators
├── admin/
│   ├── providers/         # Admin auth/session, alerts, data & analytics
│   ├── router/            # Admin navigation
│   ├── screens/           # Admin screens
│   └── services/          # Admin-only services (alerts)
├── data/
│   ├── datasources/       # Seed/mock data
│   └── repositories/      # Repository layer over FirestoreService
├── domain/
│   └── entities/          # Core data models
├── presentation/
│   ├── providers/         # Customer-facing state
│   ├── router/            # Customer navigation
│   ├── screens/           # Customer screens
│   └── widgets/           # Reusable widgets
└── services/              # Firebase-backed services (Firestore, auth, ...)

functions/                 # Trusted server-side logic (TypeScript, Node 20)
└── src/index.ts           # placeOrder, setAdminRole, removeAdminRole
```

## Architecture

The app follows a layered approach. UI widgets depend on Riverpod providers,
which depend on the repository layer, which wraps the Firebase services. This
keeps widgets free of Firebase specifics and makes the data layer testable.

- **`core/error`** — `Result<T>` plus typed `Failure`s. Repositories return
  `Result` and never throw across the boundary; `ErrorMapper` turns any
  exception into a user-safe message.
- **`core/logging`** — `AppLogger` is the single logging entry point. Avoid
  `print()` (enforced as an analyzer error).
- **`data/repositories`** — products, categories, orders and support tickets.
  Screens and providers go through these rather than calling `FirestoreService`
  directly.
- **Authorization** — privileged admin actions call `requireAdmin(...)` with a
  minimum `AdminRole`, so authorization is checked in one place.

## Testing

```bash
flutter analyze        # static analysis (must be clean)
flutter test           # unit + widget tests
flutter test --coverage
```

Unit tests cover validators, the `Result`/`Failure` layer, core entities and
the admin analytics aggregations.

## Continuous Integration

`.github/workflows/ci.yml` runs analyze + tests + a debug build on every push
and pull request, and a release build on `main`. `.github/workflows/build-apk.yml`
produces customer and admin APK artifacts.
