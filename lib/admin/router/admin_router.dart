import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_auth_provider.dart';
import '../screens/admin_login_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_products_screen.dart';
import '../screens/admin_add_product_screen.dart';
import '../screens/admin_orders_screen.dart';
import '../screens/admin_categories_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/admin_tickets_screen.dart';
import '../../domain/entities/product.dart';

final _adminNavigatorKey = GlobalKey<NavigatorState>();

final adminRouter = GoRouter(
  navigatorKey: _adminNavigatorKey,
  initialLocation: '/admin/login',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final isLoggedIn = container.read(isAdminLoggedInProvider);
    final isLoginRoute = state.matchedLocation == '/admin/login';
    if (!isLoggedIn && !isLoginRoute) return '/admin/login';
    if (isLoggedIn && isLoginRoute) return '/admin';
    return null;
  },
  routes: [
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'products',
          builder: (context, state) => const AdminProductsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) =>
                  const AdminAddProductScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) {
                // Prefer the full Product passed as extra; fall back to ID
                final product = state.extra as Product?;
                return AdminAddProductScreen(
                  product: product,
                  productId: product == null
                      ? state.pathParameters['id']
                      : null,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const AdminOrdersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => _OrderDetailScreen(
                  orderId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) =>
              const AdminCategoriesScreen(),
        ),
        GoRoute(
          path: 'analytics',
          builder: (context, state) =>
              const AdminAnalyticsScreen(),
        ),
        GoRoute(
          path: 'tickets',
          builder: (context, state) =>
              const AdminTicketsScreen(),
        ),
      ],
    ),
  ],
);

class _OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const _OrderDetailScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order $orderId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long,
                  size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text('Order $orderId',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Full order detail view coming soon.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Orders'),
            ),
          ],
        ),
      ),
    );
  }
}
