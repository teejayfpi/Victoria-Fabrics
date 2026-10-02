import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fabric_haven/core/providers/auth_provider.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/product.dart';
import 'package:fabric_haven/domain/entities/store_settings.dart';
import 'package:fabric_haven/presentation/providers/cart_provider.dart';
import 'package:fabric_haven/presentation/providers/settings_provider.dart';
import 'package:fabric_haven/presentation/screens/checkout_screen.dart';

const _product = Product(
  id: 'p1',
  name: 'Royal Ankara',
  description: 'Wax print',
  categoryId: 'c1',
  categoryName: 'Ankara',
  imageUrls: [],
  pricePerYard: 5000,
  pricePerMeter: 5500,
  pricePerPiece: 12000,
  inStock: true,
  colors: [],
  availableUnits: ['Yard', 'Meter', 'Piece'],
  stockCount: 10,
);

/// A cart pre-seeded with fixed items, bypassing the add-to-cart flow.
class _SeededCart extends CartNotifier {
  _SeededCart(List<CartItem> items) {
    state = items;
  }
}

/// Checkout is the screen most affected by the move away from a hard-coded
/// delivery fee, so it gets a layout guard on narrow phones plus a check that
/// the fee shown comes from store settings.
void main() {
  Widget host(StoreSettings settings, {bool withItem = true}) => ProviderScope(
        overrides: [
          storeSettingsStreamProvider
              .overrideWith((ref) => Stream.value(settings)),
          currentUserProvider.overrideWithValue(null),
          if (withItem)
            cartProvider.overrideWith((ref) => _SeededCart(const [
                  CartItem(
                    product: _product,
                    quantity: 2,
                    selectedUnit: 'Yard',
                  ),
                ])),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CheckoutScreen(),
        ),
      );

  final sizes = <String, Size>{
    'small phone': const Size(320, 568),
    'standard phone': const Size(390, 844),
  };

  for (final entry in sizes.entries) {
    testWidgets('CheckoutScreen lays out on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const StoreSettings(deliveryFee: 3500)));
      await tester.pump();

      expect(find.text('Checkout'), findsOneWidget);
    });
  }

  testWidgets('delivery fee line reflects the configured fee', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const StoreSettings(deliveryFee: 3500)));
    await tester.pump();

    expect(find.text('Delivery fee: ₦3,500'), findsOneWidget);
  });

  testWidgets('shows free delivery when the fee is zero', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const StoreSettings(deliveryFee: 0)));
    await tester.pump();

    expect(find.text('Free delivery'), findsOneWidget);
  });

  testWidgets('marks a disabled fulfilment option as unavailable',
      (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const StoreSettings(
      deliveryEnabled: false,
      pickupEnabled: true,
    )));
    await tester.pump();

    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('From our store'), findsOneWidget);
  });
}
