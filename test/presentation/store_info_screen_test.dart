import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fabric_haven/core/providers/auth_provider.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/domain/entities/store_settings.dart';
import 'package:fabric_haven/presentation/providers/settings_provider.dart';
import 'package:fabric_haven/presentation/screens/store_info_screen.dart';

/// Layout guards for the owner-published store information screen. A
/// RenderFlex overflow throws during pump, so these fail if the cards clip on
/// a narrow phone — the reported "screens not aligned" symptom.
void main() {
  final sizes = <String, Size>{
    'small phone': const Size(320, 568),
    'standard phone': const Size(390, 844),
    'tablet': const Size(1024, 1366),
  };

  Widget host(StoreSettings settings) => ProviderScope(
        overrides: [
          storeSettingsStreamProvider
              .overrideWith((ref) => Stream.value(settings)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoreInfoScreen(),
        ),
      );

  for (final entry in sizes.entries) {
    testWidgets('StoreInfoScreen lays out on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const StoreSettings(
        storeName: 'Victoria Fabrics',
        addressLine: '12 Broad Street',
        city: 'Lagos',
        state: 'Lagos',
        deliveryFee: 3500,
        contactEmail: 'hello@victoriafabrics.example',
      )));
      await tester.pump();

      expect(find.text('Store Information'), findsOneWidget);
      expect(find.text('Victoria Fabrics'), findsWidgets);
    });
  }

  testWidgets('shows the delivery fee the owner configured', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const StoreSettings(deliveryFee: 3500)));
    await tester.pump();

    expect(
      find.textContaining('Flat fee of 3500'),
      findsOneWidget,
    );
  });

  testWidgets('says delivery is unavailable when switched off', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const StoreSettings(
      deliveryEnabled: false,
      pickupEnabled: true,
    )));
    await tester.pump();

    expect(find.text('Delivery is currently unavailable.'), findsOneWidget);
  });

  testWidgets('prefill helper is unaffected by a signed-out user',
      (tester) async {
    // Sanity check that the screen does not require a signed-in customer.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        storeSettingsStreamProvider
            .overrideWith((ref) => Stream.value(const StoreSettings())),
        currentUserProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const StoreInfoScreen(),
      ),
    ));
    await tester.pump();

    expect(find.text('Store Information'), findsOneWidget);
  });
}
