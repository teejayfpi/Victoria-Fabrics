import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_auth_provider.dart';
import '../screens/admin_login_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_products_screen.dart';
import '../screens/admin_add_product_screen.dart';
import '../screens/admin_orders_screen.dart';
import '../screens/admin_categories_screen.dart';
import '../screens/admin_analytics_screen.dart';

final adminRouter = GoRouter(
  initialLocation: '/admin',
  redirect: (context, state) {
    final isLoggedIn = state.uri.toString() == '/admin/login';
    final authToken = ''; // Would check adminAuthProvider here
    
    // For demo mode, allow access to all admin routes
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
              builder: (context, state) => const AdminAddProductScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => AdminAddProductScreen(
                productId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => AdminAddProductScreen(
                productId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const AdminOrdersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => _OrderDetailPlaceholder(
                orderId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) => const AdminCategoriesScreen(),
        ),
        GoRoute(
          path: 'analytics',
          builder: (context, state) => const AdminAnalyticsScreen(),
        ),
      ],
    ),
  ],
);

class _OrderDetailPlaceholder extends StatelessWidget {
  final String orderId;

  const _OrderDetailPlaceholder({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order $orderId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Order Details: $orderId'),
            const SizedBox(height: 8),
            const Text('Demo mode - full details would be shown here'),
          ],
        ),
      ),
    );
  }
}