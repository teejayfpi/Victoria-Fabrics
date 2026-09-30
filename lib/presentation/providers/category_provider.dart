import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../domain/entities/category.dart';

/// The category catalogue with its loading/error states intact.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

/// Convenience sync provider — returns the current list (empty until loaded).
final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesStreamProvider).valueOrNull ?? const [];
});

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider);
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});