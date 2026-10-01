/// Application-wide, non-secret constants.
///
/// Domain enums (order status, delivery type, measurement units) live next to
/// the entities they describe — see `lib/domain/entities/`. Credentials and
/// environment-specific values belong in `AppConfig` (build-time) or Firestore,
/// never here.
class AppConstants {
  AppConstants._();

  static const String appName = 'Victoria Fabrics';
  static const String adminAppName = 'VF Admin';
  static const String appTagline =
      'Premium Ankara, Lace & Cotton, delivered.';
  static const String currencySymbol = '₦';
  static const String currencyCode = 'NGN';

  /// Flat delivery fee in Naira, applied to delivery orders.
  static const double deliveryFee = 2500;

  static const List<String> measurementUnits = ['Yard', 'Meter', 'Piece'];
}

enum MeasurementUnit {
  yard,
  meter,
  piece;

  String get displayName {
    switch (this) {
      case MeasurementUnit.yard:
        return 'Yard';
      case MeasurementUnit.meter:
        return 'Meter';
      case MeasurementUnit.piece:
        return 'Piece';
    }
  }

  String get abbreviation {
    switch (this) {
      case MeasurementUnit.yard:
        return 'yd';
      case MeasurementUnit.meter:
        return 'm';
      case MeasurementUnit.piece:
        return 'pc';
    }
  }
}
