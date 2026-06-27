import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/mock_data_source.dart';
import '../../domain/entities/category.dart';

final categoriesProvider = Provider<List<Category>>((ref) {
  print('[Fabric Haven] Loading categories...');
  return MockDataSource.categories;
});

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider);
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (e) {
    return null;
  }
});