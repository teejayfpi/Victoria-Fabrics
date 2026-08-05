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

## Admin Login

- **Email:** admin@victoriafabrics.com
- **Password:** Victoria@2024

## Tech Stack

- Flutter 3.24 / Dart 3.5
- Firebase (Auth + Firestore)
- Riverpod (state management)
- GoRouter (navigation)
- Cached Network Image

## Firebase

The `google-services.json` is included at `android/app/google-services.json` for the Firebase project `victoria-fabrics`.

## Project Structure

```
lib/
├── main.dart              # Customer app entry point
├── main_admin.dart        # Admin app entry point
├── core/
│   ├── constants/         # App-wide constants & enums
│   ├── providers/         # Firebase auth providers
│   └── theme/             # App theme
├── admin/
│   ├── providers/         # Admin auth state
│   ├── router/            # Admin navigation
│   └── screens/           # Admin screens
├── data/
│   └── datasources/       # Mock data (to be replaced with Firestore)
├── domain/
│   └── entities/          # Core data models
└── presentation/
    ├── providers/          # Customer-facing state
    ├── router/             # Customer navigation
    ├── screens/            # Customer screens
    └── widgets/            # Reusable widgets
```
