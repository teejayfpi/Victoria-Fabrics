import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_auth_provider.dart';
import '../screens/admin_login_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_products_screen.dart';
import '../screens/admin_add_product_screen.dart';
import '../screens/admin_orders_screen.dart';
import '../screens/admin_order_detail_screen.dart';
import '../screens/admin_categories_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/admin_tickets_screen.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/admin_profile_screen.dart';
import '../screens/admin_splash_screen.dart';
import '../../domain/entities/product.dart';
import '../providers/admin_data_providers.dart';

final _adminNavigatorKey = GlobalKey<NavigatorState>();

final adminRouter = GoRouter(
  navigatorKey: _adminNavigatorKey,
  initialLocation: '/admin/splash',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final isLoggedIn = container.read(isAdminLoggedInProvider);
    final loc = state.matchedLocation;
    // The splash screen owns its own hand-off.
    if (loc == '/admin/splash') return null;
    final isLoginRoute = loc == '/admin/login';
    if (!isLoggedIn && !isLoginRoute) return '/admin/login';
    if (isLoggedIn && isLoginRoute) return '/admin';
    return null;
  },
  routes: [
    GoRoute(
      path: '/admin/splash',
      builder: (context, state) => const AdminSplashScreen(),
    ),
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
              builder: (context, state) {
                // Prefer the full Product passed as extra; fall back to ID
                final product = state.extra as Product?;
                return AdminAddProductScreen(
                  product: product,
                  productId:
                      product == null ? state.pathParameters['id'] : null,
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
              builder: (context, state) => AdminOrderDetailScreen(
                orderId: state.pathParameters['id']!,
                initialOrder: state.extra as AdminOrder?,
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
        GoRoute(
          path: 'tickets',
          builder: (context, state) => const AdminTicketsScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const AdminProfileScreen(),
        ),
      ],
    ),
  ],
);
