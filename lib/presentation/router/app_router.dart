import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/category_products_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/order_confirmation_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/support_ticket_screen.dart';
import '../screens/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that require a signed-in user
const _protectedRoutes = ['/checkout', '/orders'];

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isSignedIn = user != null;
    final loc = state.matchedLocation;

    // Redirect to sign-in if trying to access a protected route
    if (!isSignedIn && _protectedRoutes.any((r) => loc.startsWith(r))) {
      return '/signin?from=${Uri.encodeComponent(loc)}';
    }
    // Already signed in and going to sign-in → send home
    if (isSignedIn && loc == '/signin') return '/';
    return null;
  },
  routes: [
    // Sign-in screen (outside the shell so no bottom nav)
    GoRoute(
      path: '/signin',
      builder: (context, state) {
        final from = state.uri.queryParameters['from'];
        return SignInScreen(redirectTo: from);
      },
    ),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CategoriesScreen()),
        ),
        GoRoute(
          path: '/cart',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CartScreen()),
        ),
        GoRoute(
          path: '/support',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SupportTicketScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),

    GoRoute(
      path: '/category/:id',
      builder: (context, state) =>
          CategoryProductsScreen(categoryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) =>
          ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) => const OrderConfirmationScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersScreen(),
    ),
  ],
);
