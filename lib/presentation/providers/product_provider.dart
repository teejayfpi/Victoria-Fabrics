import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../services/firestore_service.dart';

// ─── Firestore stream providers ───────────────────────────────────────────────

final allProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  return FirestoreService.instance.productsStream();
});

// Convenience sync provider — returns the current list (empty until loaded)
final allProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(allProductsStreamProvider).valueOrNull ?? [];
});

final featuredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(allProductsProvider);
  return products.where((p) => p.inStock).take(6).toList();
});

final productsByCategoryProvider =
    Provider.family<List<Product>, String>((ref, categoryId) {
  return ref
      .watch(allProductsProvider)
      .where((p) => p.categoryId == categoryId)
      .toList();
});

final productByIdProvider =
    Provider.family<Product?, String>((ref, id) {
  try {
    return ref.watch(allProductsProvider).firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

// ─── Search / filter ─────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Product>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final products = ref.watch(allProductsProvider);
  if (query.isEmpty) return products;
  return products
      .where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.categoryName.toLowerCase().contains(query))
      .toList();
});

final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  if (categoryId == null) return ref.watch(allProductsProvider);
  return ref.watch(productsByCategoryProvider(categoryId));
});
