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
import '../screens/register_screen.dart';
import '../screens/support_ticket_screen.dart';
import '../screens/main_shell.dart';
import '../screens/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// The only routes reachable while signed out. Everything else requires an
/// authenticated user, so the catalogue and account area are never exposed to
/// anonymous visitors.
const Set<String> _publicRoutes = {'/signin', '/register'};

/// Route shown while the branded splash animation plays.
const String splashRoute = '/splash';

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: splashRoute,
  redirect: (context, state) {
    final isSignedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;

    // The splash screen owns its own hand-off to the next route.
    if (loc == splashRoute) return null;

    final isPublic = _publicRoutes.contains(loc);
    if (!isSignedIn && !isPublic) {
      // Preserve the full target (path + query) so deep links survive sign-in.
      final from = Uri.encodeComponent(state.uri.toString());
      return '/signin?from=$from';
    }
    if (isSignedIn && isPublic) return '/';
    return null;
  },
  routes: [
    // Branded splash (outside the shell so no bottom nav)
    GoRoute(
      path: splashRoute,
      builder: (context, state) => const SplashScreen(),
    ),

    // Sign-in screen (outside the shell so no bottom nav)
    GoRoute(
      path: '/signin',
      builder: (context, state) {
        final from = state.uri.queryParameters['from'];
        return SignInScreen(redirectTo: from);
      },
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) {
        final from = state.uri.queryParameters['from'];
        return RegisterScreen(redirectTo: from);
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
