import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fabric_haven/admin/providers/admin_auth_provider.dart';
import 'package:fabric_haven/admin/screens/admin_profile_screen.dart';
import 'package:fabric_haven/admin/screens/admin_settings_screen.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/domain/entities/store_settings.dart';
import 'package:fabric_haven/presentation/providers/settings_provider.dart';

/// Builds the settings form from a fixed [StoreSettings] value, bypassing
/// Firestore, so the field defaults and the both-methods-disabled guard can be
/// checked without a live backend.
Widget _settingsHost(StoreSettings settings) => ProviderScope(
      overrides: [
        storeSettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminSettingsScreen(),
      ),
    );

void main() {
  /// Gives the form enough vertical room to render without scrolling, so taps
  /// land on the intended widgets.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('settings form is prefilled from the current store settings',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(_settingsHost(const StoreSettings(
      storeName: 'Victoria Fabrics',
      addressLine: '12 Broad Street',
      city: 'Lagos',
      state: 'Lagos',
      deliveryFee: 3500,
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Store Settings'), findsOneWidget);
    expect(find.text('Victoria Fabrics'), findsOneWidget);
    expect(find.text('12 Broad Street'), findsOneWidget);
    // 3500 renders without a trailing ".00".
    expect(find.text('3500'), findsOneWidget);
  });

  testWidgets('refuses to save when both delivery and pickup are switched off',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(_settingsHost(const StoreSettings()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.tap(find.byType(Switch).last);
    await tester.pump();

    await tester.tap(find.text('Save settings'));
    await tester.pump();

    expect(find.text('Enable delivery, pickup, or both.'), findsOneWidget);
  });

  testWidgets('rejects a non-numeric delivery fee', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(_settingsHost(const StoreSettings()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Delivery fee (₦)'), 'free');
    await tester.tap(find.text('Save settings'));
    await tester.pump();

    expect(find.text('Enter a number'), findsOneWidget);
  });

  testWidgets('admin profile screen renders the signed-in administrator',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentAdminProvider.overrideWithValue(const AdminUser(
          id: 'a1',
          email: 'owner@example.com',
          name: 'Ada Obi',
          role: AdminRole.admin,
          phone: '08030000000',
        )),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminProfileScreen(),
      ),
    ));
    await tester.pump();

    expect(find.text('Ada Obi'), findsWidgets);
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });
}
