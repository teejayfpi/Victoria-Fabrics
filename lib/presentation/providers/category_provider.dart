import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../services/firestore_service.dart';

/// Live category list from Firestore.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return FirestoreService.instance.categoriesStream();
});

/// Synchronous view of the catalogue, used by screens that render a list
/// directly. Empty until the first Firestore snapshot arrives.
final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesStreamProvider).maybeWhen(
        data: (categories) => categories,
        orElse: () => const [],
      );
});

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider);
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});