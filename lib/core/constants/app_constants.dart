class AppConstants {
  static const String appName = 'Victoria Fabrics';
  static const String adminEmail = 'admin@victoriafabrics.com';
  static const String currencySymbol = '₦';
  static const String currencyCode = 'NGN';

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

enum DeliveryType {
  delivery,
  pickup;

  String get displayName {
    switch (this) {
      case DeliveryType.delivery:
        return 'Delivery';
      case DeliveryType.pickup:
        return 'Pickup';
    }
  }
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
