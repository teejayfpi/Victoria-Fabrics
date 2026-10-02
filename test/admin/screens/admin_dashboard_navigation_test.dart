import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fabric_haven/admin/providers/admin_auth_provider.dart';
import 'package:fabric_haven/admin/providers/admin_data_providers.dart';
import 'package:fabric_haven/admin/screens/admin_dashboard_screen.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/order.dart';
import 'package:fabric_haven/domain/entities/product.dart';
import 'package:fabric_haven/presentation/providers/product_provider.dart';

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

AdminOrder _order() => AdminOrder(
      firestoreId: 'doc1',
      order: Order(
        id: 'abc123',
        userId: 'user-1',
        items: const [
          CartItem(
            product: _product,
            quantity: 1,
            selectedUnit: 'Yard',
            unitPriceOverride: 1500,
          ),
        ],
        totalAmount: 1500,
        status: OrderStatus.pending,
        deliveryType: DeliveryType.delivery,
        deliveryAddress: '12 Broad Street, Lagos',
        customerName: 'Ada Obi',
        customerPhone: '08030000000',
        createdAt: DateTime(2026, 1, 1, 9, 30),
      ),
    );

const _admin = AdminUser(
  id: 'a1',
  email: 'owner@example.com',
  name: 'Ada Obi',
  role: AdminRole.admin,
);

/// Guards the reported "cards do nothing" symptom: every dashboard tile must
/// actually navigate. The dashboard is mounted under a real GoRouter so a
/// missing/incorrect route is caught instead of passing silently.
void main() {
  late GoRouter router;

  Widget host() {
    router = GoRouter(
      initialLocation: '/admin',
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) =>
              const Scaffold(body: Text('products')),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const Scaffold(body: Text('orders')),
        ),
        GoRoute(
          path: '/admin/orders/:id',
          builder: (context, state) => Scaffold(
            body: Text('order-detail:${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/admin/tickets',
          builder: (context, state) =>
              const Scaffold(body: Text('tickets')),
        ),
        GoRoute(
          path: '/admin/analytics',
          builder: (context, state) =>
              const Scaffold(body: Text('analytics')),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) =>
              const Scaffold(body: Text('settings')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentAdminProvider.overrideWithValue(_admin),
        adminOrdersProvider.overrideWith((ref) => Stream.value([_order()])),
        adminTicketsProvider.overrideWith((ref) => Stream.value(const [])),
        allProductsStreamProvider.overrideWith((ref) => Stream.value([_product])),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('a stat card opens the products screen', (tester) async {
    await settle(tester);
    await tester.tap(find.text('Total Products'));
    await tester.pumpAndSettle();

    // `push` keeps the dashboard on the stack, so assert on the destination
    // actually being rendered rather than on the reported base location.
    expect(find.text('products'), findsOneWidget);
  });

  testWidgets('a recent-order tile opens that order, not the list',
      (tester) async {
    await settle(tester);
    await tester.tap(find.text('VF-ABC123'));
    await tester.pumpAndSettle();

    expect(find.text('order-detail:doc1'), findsOneWidget);
  });

  testWidgets('quick actions open the settings screen', (tester) async {
    await settle(tester);
    await tester.tap(find.text('Store Settings'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);
  });
}
