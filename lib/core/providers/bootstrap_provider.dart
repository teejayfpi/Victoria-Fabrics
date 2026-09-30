import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import 'repository_providers.dart';

/// One-time, best-effort catalogue bootstrap.
///
/// Seeds the products and categories collections from the bundled defaults the
/// first time the app runs against an empty database. The underlying Firestore
/// writes are idempotent (guarded by a write-once `_meta` marker) and require
/// the staff role, so a normal customer launch simply no-ops.
///
/// Awaiting this is never required for the UI to render — call it fire-and-
/// forget at startup.
final catalogueBootstrapProvider = FutureProvider<void>((ref) async {
  final products = await ref.read(productRepositoryProvider).seedIfEmpty();
  products.fold(
    onSuccess: (_) {},
    onError: (failure) => AppLogger.debug(
      'Product seed skipped: ${failure.message}',
      tag: 'bootstrap',
    ),
  );

  final categories = await ref.read(categoryRepositoryProvider).seedIfEmpty();
  categories.fold(
    onSuccess: (_) {},
    onError: (failure) => AppLogger.debug(
      'Category seed skipped: ${failure.message}',
      tag: 'bootstrap',
    ),
  );
});
