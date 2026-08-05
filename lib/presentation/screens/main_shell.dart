import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/categories')) return 1;
    if (loc.startsWith('/cart')) return 2;
    if (loc.startsWith('/support')) return 3;
    if (loc.startsWith('/profile') || loc.startsWith('/orders')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/categories');
      case 2:
        context.go('/cart');
      case 3:
        context.go('/support');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final idx = _selectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryColor.withOpacity(0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: AppTheme.primaryColor),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart,
                  color: AppTheme.primaryColor),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon:
                Icon(Icons.support_agent, color: AppTheme.primaryColor),
            label: 'Support',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
