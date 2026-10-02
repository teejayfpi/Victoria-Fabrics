import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/cart_actions.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card.dart';
import '../../core/error/error_mapper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
    if (query.isNotEmpty) {
      context.push('/search');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);
    final categories = categoriesAsync.valueOrNull ?? const [];
    final featuredProducts = (productsAsync.valueOrNull ?? const [])
        .where((p) => p.inStock)
        .take(6)
        .toList();

    // If the catalogue cannot be read, say so once rather than showing two
    // empty shelves. A silent failure here is indistinguishable from a store
    // that genuinely has no products.
    final catalogError = productsAsync.error ?? categoriesAsync.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Victoria Fabrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: catalogError != null
          ? AppErrorState(
              title: 'Could not load the catalogue',
              message: ErrorMapper.map(catalogError, StackTrace.current).message,
              onRetry: () {
                ref.invalidate(categoriesStreamProvider);
                ref.invalidate(allProductsStreamProvider);
              },
            )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search fabrics...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
                onSubmitted: _onSearch,
                onChanged: (value) => setState(() {}),
              ),
            ),

            // Categories section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/categories'),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return SizedBox(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CategoryCard(
                        category: category,
                        onTap: () => context.push('/category/${category.id}'),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Featured products section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Featured Fabrics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                  isWishlisted: ref.watch(isWishlistedProvider(product.id)),
                  onToggleWishlist: () =>
                      ref.read(userDataControllerProvider).toggleWishlist(product.id),
                  onAddToCart: () => quickAddToCart(context, ref, product),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
