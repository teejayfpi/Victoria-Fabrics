/// Deployment target the app was built for.
enum Environment {
  development,
  staging,
  production;

  bool get isProduction => this == Environment.production;
  bool get isDevelopment => this == Environment.development;

  static Environment fromName(String value) {
    return Environment.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => Environment.development,
    );
  }
}

/// Build-time configuration supplied via `--dart-define`.
///
/// Example:
/// ```
/// flutter build apk --release \
///   --dart-define=ENV=production \
///   --dart-define=SENTRY_DSN=https://...
/// ```
///
/// Nothing here is a secret. Anything compiled into a client binary — including
/// API keys and `google-services.json` — is recoverable from the shipped APK.
/// Treat server-side security rules as the real trust boundary.
class AppConfig {
  AppConfig._();

  static const String _envName =
      String.fromEnvironment('ENV', defaultValue: 'development');

  static Environment get environment => Environment.fromName(_envName);

  /// Optional crash-reporting DSN. Empty in local builds.
  static const String crashReportingDsn =
      String.fromEnvironment('CRASH_REPORTING_DSN');

  /// Google OAuth web client ID used for native Google Sign-In.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1010144166475-6ke40f39m9f4tim92q46gu8p75igqeci.apps.googleusercontent.com',
  );

  /// Remote config / feature flags that can be toggled per environment.
  static const bool enableAdminApp =
      bool.fromEnvironment('ENABLE_ADMIN_APP', defaultValue: true);

  /// Maximum product image size accepted for upload, in bytes (5 MiB).
  static const int maxImageUploadBytes = 5 * 1024 * 1024;

  /// Firestore collection names, centralised so a rename is a one-line change.
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String ticketsCollection = 'tickets';
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String settingsCollection = 'settings';

  /// Single document holding the owner-editable store settings (delivery fee,
  /// shop address, contact details).
  static const String storeSettingsDoc = 'store';
}
