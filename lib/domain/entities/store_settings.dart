import '../../core/constants/app_constants.dart';
import '../../core/constants/payment_constants.dart';

/// Store-wide settings the owner controls from the admin portal and every
/// customer reads.
///
/// Persisted as the single `settings/store` document. Prices and the pickup
/// address used to be compiled into the APK (`AppConstants.deliveryFee` and a
/// hard-coded "15 Admiralty Way" string), so changing the delivery fee or the
/// shop address meant shipping a new build. They now live here instead.
///
/// The `store` document is world-readable — the storefront needs the fee to
/// render a total before checkout — and writable only by staff (see
/// `firestore.rules`). Nothing sensitive belongs in it.
class StoreSettings {
  const StoreSettings({
    this.storeName = AppConstants.appName,
    this.addressLine = '',
    this.city = '',
    this.state = '',
    this.deliveryFee = AppConstants.deliveryFee,
    this.deliveryEnabled = true,
    this.pickupEnabled = true,
    this.contactPhone = PaymentConstants.whatsappDisplay,
    this.contactWhatsapp = PaymentConstants.whatsappNumber,
    this.contactEmail = '',
  });

  final String storeName;

  /// Street address of the shop, shown to customers choosing pickup.
  final String addressLine;
  final String city;
  final String state;

  /// Flat fee in Naira applied to delivery orders. Zero means free delivery.
  final double deliveryFee;

  /// Whether the store currently offers each fulfilment method. Both default to
  /// true; the owner may switch one off (e.g. pause delivery during a sale).
  final bool deliveryEnabled;
  final bool pickupEnabled;

  final String contactPhone;
  final String contactWhatsapp;
  final String contactEmail;

  /// Single-line pickup address for display, e.g. `12 Broad St, Lagos, Lagos`.
  /// Falls back to the store name when no address has been configured yet, so
  /// pickup orders never show an empty location.
  String get formattedAddress {
    final parts = [addressLine, city, state]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return storeName;
    return parts.join(', ');
  }

  /// The pickup location recorded on an order, matching [formattedAddress]
  /// with the store name in front.
  String get pickupLocation => '$storeName\n$formattedAddress';

  /// True when there is at least one way for a customer to receive an order.
  bool get hasFulfilmentOption => deliveryEnabled || pickupEnabled;

  StoreSettings copyWith({
    String? storeName,
    String? addressLine,
    String? city,
    String? state,
    double? deliveryFee,
    bool? deliveryEnabled,
    bool? pickupEnabled,
    String? contactPhone,
    String? contactWhatsapp,
    String? contactEmail,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      pickupEnabled: pickupEnabled ?? this.pickupEnabled,
      contactPhone: contactPhone ?? this.contactPhone,
      contactWhatsapp: contactWhatsapp ?? this.contactWhatsapp,
      contactEmail: contactEmail ?? this.contactEmail,
    );
  }

  Map<String, dynamic> toMap() => {
        'storeName': storeName,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'deliveryFee': deliveryFee,
        'deliveryEnabled': deliveryEnabled,
        'pickupEnabled': pickupEnabled,
        'contactPhone': contactPhone,
        'contactWhatsapp': contactWhatsapp,
        'contactEmail': contactEmail,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory StoreSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const StoreSettings();
    final rawFee = map['deliveryFee'];
    return StoreSettings(
      storeName: _string(map['storeName'], AppConstants.appName),
      addressLine: _string(map['addressLine'], ''),
      city: _string(map['city'], ''),
      state: _string(map['state'], ''),
      deliveryFee:
          rawFee is num ? rawFee.toDouble().clamp(0, 100000000).toDouble() : AppConstants.deliveryFee,
      deliveryEnabled: map['deliveryEnabled'] as bool? ?? true,
      pickupEnabled: map['pickupEnabled'] as bool? ?? true,
      contactPhone: _string(map['contactPhone'], PaymentConstants.whatsappDisplay),
      contactWhatsapp:
          _string(map['contactWhatsapp'], PaymentConstants.whatsappNumber),
      contactEmail: _string(map['contactEmail'], ''),
    );
  }

  static String _string(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }
}
