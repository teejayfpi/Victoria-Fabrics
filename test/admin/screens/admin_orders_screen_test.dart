import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fabric_haven/admin/providers/admin_data_providers.dart';
import 'package:fabric_haven/admin/screens/admin_orders_screen.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/order.dart';
import 'package:fabric_haven/domain/entities/product.dart';

Widget _host(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminOrdersScreen(),
      ),
    );

const _product = Product(
  id: 'p1',
  name: 'Ankara Wax',
  description: 'Wax print',
  categoryId: 'c1',
  categoryName: 'Ankara',
  imageUrls: [],
  pricePerYard: 1500,
  pricePerMeter: 1800,
  pricePerPiece: 9000,
  inStock: true,
  colors: [],
  availableUnits: ['Yard', 'Meter', 'Piece'],
);

AdminOrder _order(String id, OrderStatus status, {String name = 'Ada Obi'}) =>
    AdminOrder(
      firestoreId: id,
      order: Order(
        id: id,
        userId: 'user-1',
        items: const [
          CartItem(
            product: _product,
            quantity: 2,
            selectedUnit: 'Yard',
            unitPriceOverride: 1500,
          ),
        ],
        totalAmount: 3000,
        status: status,
        deliveryType: DeliveryType.delivery,
        deliveryAddress: '12 Broad Street, Lagos',
        customerName: name,
        customerPhone: '08030000000',
        createdAt: DateTime(2026, 1, 1, 9, 30),
      ),
    );

/// Regression guard for the reported "admin orders do nothing" symptom: when
/// the orders read fails (missing index, rules denial, offline) the screen must
/// surface the failure and offer a retry instead of rendering an empty list
/// that looks like a store with no orders.
void main() {
  testWidgets('shows an error with retry when the orders stream fails',
      (tester) async {
    await tester.pumpWidget(_host([
      adminOrdersProvider.overrideWith(
        (ref) => Stream<List<AdminOrder>>.error(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'The query requires an index.',
          ),
        ),
      ),
    ]));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text('The data changed while you were working. Please retry.'),
      findsOneWidget,
    );
  });

  testWidgets('lists orders when the stream succeeds', (tester) async {
    await tester.pumpWidget(_host([
      adminOrdersProvider.overrideWith(
        (ref) => Stream.value([
          _order('o1', OrderStatus.pending),
          _order('o2', OrderStatus.delivered),
        ]),
      ),
    ]));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Ada Obi'), findsNWidgets(2));
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no orders', (tester) async {
    await tester.pumpWidget(_host([
      adminOrdersProvider.overrideWith((ref) => Stream.value(const [])),
    ]));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No orders found'), findsOneWidget);
  });

  testWidgets('search narrows orders by customer name', (tester) async {
    await tester.pumpWidget(_host([
      adminOrdersProvider.overrideWith(
        (ref) => Stream.value([
          _order('o1', OrderStatus.pending, name: 'Ada Obi'),
          _order('o2', OrderStatus.pending, name: 'Bola Ade'),
        ]),
      ),
    ]));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('Bola Ade'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'bola');
    await tester.pump();

    expect(find.text('Ada Obi'), findsNothing);
    expect(find.text('Bola Ade'), findsOneWidget);
  });

  testWidgets('search with no hits shows the matching empty state',
      (tester) async {
    await tester.pumpWidget(_host([
      adminOrdersProvider.overrideWith(
        (ref) => Stream.value([_order('o1', OrderStatus.pending)]),
      ),
    ]));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pump();

    expect(find.text('No matching orders'), findsOneWidget);
  });
}
