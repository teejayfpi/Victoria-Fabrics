import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../../core/widgets/async_state.dart';
import '../../domain/entities/category.dart';

class CategoryProductsScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);

    // Show the name only once the category list has arrived; until then the
    // app bar carries a neutral title rather than flickering or bailing out.
    final category = categoriesAsync.valueOrNull?.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => const Category(
        id: '',
        name: 'Category',
        description: '',
        imageUrl: '',
        iconName: 'checkroom',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name.isNotEmpty == true
            ? category!.name
            : 'Category'),
      ),
      body: productsAsync.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          title: 'Could not load products',
          error: error,
          onRetry: () => ref.invalidate(allProductsStreamProvider),
        ),
        data: (allProducts) {
          final products =
              allProducts.where((p) => p.categoryId == categoryId).toList();

          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing here yet',
              message: 'No fabrics have been added to this category.',
            );
          }

          return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                );
              },
          );
        },
      ),
    );
  }
}