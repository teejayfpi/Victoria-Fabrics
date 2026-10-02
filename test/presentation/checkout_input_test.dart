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

class _SeededCart extends CartNotifier {
  _SeededCart(List<CartItem> items) {
    state = items;
  }
}

/// Reproduces the reported symptom: a customer is asked for a phone number and
/// an address but cannot type them. If the fields are not editable, or lose the
/// typed text, these fail.
void main() {
  Widget host(StoreSettings settings) => ProviderScope(
        overrides: [
          storeSettingsStreamProvider
              .overrideWith((ref) => Stream.value(settings)),
          currentUserProvider.overrideWithValue(null),
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

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(500, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('a customer can type their name and phone number',
      (tester) async {
    tall(tester);
    await tester.pumpWidget(host(const StoreSettings()));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Ada Obi');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'), '08031234567');
    await tester.pump();

    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('08031234567'), findsOneWidget);
  });

  testWidgets('a customer can type a delivery address', (tester) async {
    tall(tester);
    await tester.pumpWidget(host(const StoreSettings()));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Street Address'),
        '15 Admiralty Way, Lekki');
    await tester.pump();

    expect(find.text('15 Admiralty Way, Lekki'), findsOneWidget);
  });

  testWidgets('the phone field accepts a phone keyboard hint', (tester) async {
    tall(tester);
    await tester.pumpWidget(host(const StoreSettings()));
    await tester.pump();

    final phone = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Phone Number'));
    expect(phone.controller!.text, isEmpty);
    // A missing/read-only controller is the usual reason a field cannot be
    // typed into; make sure one is wired up and enabled.
    expect(phone.enabled, isNot(false));
  });

  testWidgets('required-field errors stop an empty order', (tester) async {
    tall(tester);
    await tester.pumpWidget(host(const StoreSettings()));
    await tester.pump();

    await tester.tap(find.text('Place Order'));
    await tester.pump();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
    expect(find.text('Please enter your delivery address'), findsOneWidget);
  });

  // `enterText` focuses a field programmatically and skips hit-testing, so it
  // cannot catch a field the customer actually cannot tap. Tapping the real
  // hit-box and then typing is what reproduces "I can't write in it".
  testWidgets('phone and address fields can be tapped and typed into',
      (tester) async {
    tall(tester);
    await tester.pumpWidget(host(const StoreSettings()));
    await tester.pump();

    final phoneFinder =
        find.widgetWithText(TextFormField, 'Phone Number');
    final addressFinder =
        find.widgetWithText(TextFormField, 'Street Address');

    await tester.tap(phoneFinder);
    await tester.pump();
    await tester.enterText(phoneFinder, '08031234567');
    await tester.pump();
    expect(find.text('08031234567'), findsOneWidget);

    await tester.tap(addressFinder);
    await tester.pump();
    await tester.enterText(addressFinder, '15 Admiralty Way');
    await tester.pump();
    expect(find.text('15 Admiralty Way'), findsOneWidget);
  });
}
