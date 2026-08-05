import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/mock_data_source.dart';
import '../../domain/entities/product.dart';
import '../../presentation/providers/product_provider.dart';
import '../../services/firestore_service.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState
    extends ConsumerState<AdminProductsScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          var filtered = products;
          if (_selectedCategory != null) {
            filtered = filtered
                .where((p) => p.categoryId == _selectedCategory)
                .toList();
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filtered = filtered
                .where((p) =>
                    p.name.toLowerCase().contains(q) ||
                    p.categoryName.toLowerCase().contains(q))
                .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2,
                                size: 72, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('No products found',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context
                                  .push('/admin/products/add'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Product'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final product = filtered[i];
                          return _ProductCard(
                            product: product,
                            onEdit: () => context.push(
                              '/admin/products/edit/${product.id}',
                              extra: product,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Category',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() => _selectedCategory = null);
                    Navigator.pop(ctx);
                  },
                ),
                ...MockDataSource.categories.map((cat) => FilterChip(
                      label: Text(cat.name),
                      selected: _selectedCategory == cat.id,
                      onSelected: (selected) {
                        setState(() => _selectedCategory =
                            selected ? cat.id : null);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService.instance
                  .deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${product.name} has been removed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image, color: Colors.grey),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(product.categoryName,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '₦${product.pricePerYard.toStringAsFixed(0)}/yard',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (product.inStock
                              ? Colors.green
                              : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.inStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                          color: product.inStock
                              ? Colors.green
                              : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: AppTheme.primaryColor),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
