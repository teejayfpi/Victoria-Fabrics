import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/constants/app_constants.dart';
import 'package:fabric_haven/core/constants/payment_constants.dart';
import 'package:fabric_haven/domain/entities/store_settings.dart';

void main() {
  group('StoreSettings defaults', () {
    test('an absent document falls back to the compiled defaults', () {
      const settings = StoreSettings();

      expect(settings.storeName, AppConstants.appName);
      expect(settings.deliveryFee, AppConstants.deliveryFee);
      expect(settings.deliveryEnabled, isTrue);
      expect(settings.pickupEnabled, isTrue);
      expect(settings.contactWhatsapp, PaymentConstants.whatsappNumber);
    });

    test('fromMap(null) is the same as the defaults', () {
      final settings = StoreSettings.fromMap(null);
      expect(settings.deliveryFee, AppConstants.deliveryFee);
    });

    test('formattedAddress falls back to the store name when blank', () {
      const settings = StoreSettings(addressLine: '', city: '', state: '');
      expect(settings.formattedAddress, AppConstants.appName);
    });

    test('formattedAddress joins only the populated parts', () {
      const settings = StoreSettings(
        storeName: 'Victoria Fabrics',
        addressLine: '12 Broad Street',
        city: 'Lagos',
        state: '',
      );
      expect(settings.formattedAddress, '12 Broad Street, Lagos');
      expect(settings.pickupLocation,
          'Victoria Fabrics\n12 Broad Street, Lagos');
    });
  });

  group('StoreSettings.fromMap', () {
    test('reads stored values and round-trips through toMap', () {
      const settings = StoreSettings(
        storeName: 'VF',
        addressLine: '1 Test Way',
        city: 'Abuja',
        state: 'FCT',
        deliveryFee: 3500,
        deliveryEnabled: false,
        pickupEnabled: true,
        contactPhone: '0800 000 0000',
        contactWhatsapp: '08000000000',
        contactEmail: 'hi@example.com',
      );

      final restored = StoreSettings.fromMap(settings.toMap());

      expect(restored.storeName, 'VF');
      expect(restored.deliveryFee, 3500);
      expect(restored.deliveryEnabled, isFalse);
      expect(restored.pickupEnabled, isTrue);
      expect(restored.contactEmail, 'hi@example.com');
    });

    test('coerces an int fee and ignores an invalid one', () {
      expect(
        StoreSettings.fromMap({'deliveryFee': 4000}).deliveryFee,
        4000,
      );
      // A non-numeric fee must not crash the storefront; keep the default.
      expect(
        StoreSettings.fromMap({'deliveryFee': 'free'}).deliveryFee,
        AppConstants.deliveryFee,
      );
    });

    test('clamps a negative fee to zero', () {
      expect(StoreSettings.fromMap({'deliveryFee': -500}).deliveryFee, 0);
    });

    test('blank strings fall back to defaults rather than empty', () {
      final settings = StoreSettings.fromMap({'storeName': '   '});
      expect(settings.storeName, AppConstants.appName);
    });
  });

  group('hasFulfilmentOption', () {
    test('is true while either method is enabled', () {
      const both = StoreSettings();
      const pickupOnly = StoreSettings(deliveryEnabled: false);
      const deliveryOnly = StoreSettings(pickupEnabled: false);

      expect(both.hasFulfilmentOption, isTrue);
      expect(pickupOnly.hasFulfilmentOption, isTrue);
      expect(deliveryOnly.hasFulfilmentOption, isTrue);
    });

    test('is false only when both are switched off', () {
      const none =
          StoreSettings(deliveryEnabled: false, pickupEnabled: false);
      expect(none.hasFulfilmentOption, isFalse);
    });
  });
}
