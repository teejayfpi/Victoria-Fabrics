import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/error_mapper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state.dart';
import '../providers/user_profile_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';

/// Products the customer has saved. Backed by the `wishlist` array on
/// `users/{uid}`, so it follows the account across devices.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(wishlistIdsProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final products = productsAsync.valueOrNull ?? const [];
    final loadError = productsAsync.error ?? profileAsync.error;

    // Resolve saved ids against the live catalogue; ids whose product has been
    // removed from the store are dropped rather than shown as broken tiles.
    final saved = [
      for (final id in ids)
        ...products.where((p) => p.id == id),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: loadError != null
          ? AppErrorState(
              title: 'Could not load your wishlist',
              message: ErrorMapper.map(loadError, StackTrace.current).message,
              onRetry: () {
                ref.invalidate(allProductsStreamProvider);
                ref.invalidate(userProfileProvider);
              },
            )
          : saved.isEmpty
          ? _EmptyWishlist(hasSavedIds: ids.isNotEmpty)
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                final product = saved[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                );
              },
            ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist({required this.hasSavedIds});

  /// Distinguishes "you saved nothing" from "your saved products are no longer
  /// in the catalogue", which otherwise look identical.
  final bool hasSavedIds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasSavedIds ? 'Saved items are no longer available' : 'Your wishlist is empty',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSavedIds
                  ? 'The products you saved have been removed from the store.'
                  : 'Tap the heart on any product to save it here.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Browse fabrics'),
            ),
          ],
        ),
      ),
    );
  }
}
