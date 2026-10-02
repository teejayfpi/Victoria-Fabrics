import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/category_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../error/failures.dart';
import '../logging/app_logger.dart';
import 'repository_providers.dart';

/// Seeds the products and categories collections from the bundled defaults.
///
/// Both underlying writes are idempotent (guarded by write-once `_meta`
/// markers) and are only permitted for staff by `firestore.rules`, so this runs
/// from the admin app when a staff session appears — the point at which the
/// rules first allow the write. Without it a fresh project has no categories,
/// and the "Add Product" category picker has nothing to select.
///
/// Best-effort: a failure (e.g. the app is offline) is logged, never thrown,
/// because the catalogue is not required for the UI to render.
Future<void> seedCatalogue({
  required ProductRepository productRepository,
  required CategoryRepository categoryRepository,
}) async {
  final products = await productRepository.seedIfEmpty();
  products.fold(
    onSuccess: (_) {},
    onError: (failure) => AppLogger.debug(
      'Product seed skipped: ${failure.message}',
      tag: 'bootstrap',
    ),
  );

  final categories = await categoryRepository.seedIfEmpty();
  categories.fold(
    onSuccess: (_) {},
    onError: (failure) => AppLogger.debug(
      'Category seed skipped: ${failure.message}',
      tag: 'bootstrap',
    ),
  );
}

/// Fire-and-forget entry point for an app root: runs [seedCatalogue] once and
/// ignores the result, so the UI never blocks on the seed.
final catalogueSeederProvider = FutureProvider<void>((ref) => seedCatalogue(
      productRepository: ref.read(productRepositoryProvider),
      categoryRepository: ref.read(categoryRepositoryProvider),
    ));
