import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/mock_data_source.dart';
import '../../domain/entities/product.dart';

final allProductsProvider = Provider<List<Product>>((ref) {
  print('[Fabric Haven] Loading all products...');
  return MockDataSource.products;
});

final featuredProductsProvider = Provider<List<Product>>((ref) {
  return MockDataSource.getFeaturedProducts();
});

final productsByCategoryProvider = Provider.family<List<Product>, String>((ref, categoryId) {
  return MockDataSource.getProductsByCategory(categoryId);
});

final productByIdProvider = Provider.family<Product?, String>((ref, id) {
  return MockDataSource.getProductById(id);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Product>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return ref.watch(allProductsProvider);
  }
  return MockDataSource.searchProducts(query);
});

final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  if (categoryId == null) {
    return ref.watch(allProductsProvider);
  }
  return MockDataSource.getProductsByCategory(categoryId);
});