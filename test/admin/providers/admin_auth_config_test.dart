import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the configuration that silently breaks the admin portal without any
/// visible error in the app: the Firebase app registration for the admin
/// package, and the Android build wiring that installs the two apps side by
/// side.
///
/// The Android `google-services` plugin matches the runtime package name
/// against a `client` entry in `google-services.json`. When the admin package
/// has no entry the plugin throws at build time, so these checks catch a
/// regression before it reaches a device.
void main() {
  const customerPackage = 'com.fabrichaven.fabric_haven';
  const adminPackage = 'com.fabrichaven.fabric_haven_admin';

  Map<String, dynamic> readConfig(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  ({String appId, String apiKey}) clientFor(
    Map<String, dynamic> config,
    String packageName,
  ) {
    final client = (config['client'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (c) =>
              (c['client_info'] as Map)['android_client_info']
                  ['package_name'] == packageName,
          orElse: () => <String, dynamic>{},
        );
    if (client.isEmpty) {
      fail('No client entry for package "$packageName"');
    }
    final apiKey =
        ((client['api_key'] as List).first as Map)['current_key'] as String;
    return (
      appId: (client['client_info'] as Map)['mobilesdk_app_id'] as String,
      apiKey: apiKey,
    );
  }

  group('Firebase flavor config', () {
    test('the admin package has a matching client entry', () {
      final config =
          readConfig('android/app/src/admin/google-services.json');
      final packages = (config['client'] as List)
          .map((c) =>
              (c['client_info'] as Map)['android_client_info']['package_name'])
          .toList();
      expect(packages, contains(adminPackage));
    });

    test('both flavors carry a usable app id and API key', () {
      final customer = clientFor(
        readConfig('android/app/src/customer/google-services.json'),
        customerPackage,
      );
      final admin = clientFor(
        readConfig('android/app/src/admin/google-services.json'),
        adminPackage,
      );
      for (final client in [customer, admin]) {
        expect(client.appId, isNotEmpty);
        expect(client.apiKey, isNotEmpty);
      }
    });

    test('both flavors share the same Firebase project', () {
      final customer =
          readConfig('android/app/src/customer/google-services.json');
      final admin = readConfig('android/app/src/admin/google-services.json');
      expect(
        (admin['project_info'] as Map)['project_number'],
        (customer['project_info'] as Map)['project_number'],
        reason: 'The two apps must talk to the same Firestore/Auth project.',
      );
    });
  });

  group('Android flavor wiring', () {
    late String gradle;

    setUpAll(() {
      gradle = File('android/app/build.gradle').readAsStringSync();
    });

    test('both flavors set distinct application ids', () {
      expect(gradle, contains(customerPackage));
      expect(gradle, contains(adminPackage));
    });

    test('the admin flavor has its own display name', () {
      expect(gradle, contains('"VF Admin"'));
    });
  });
}
