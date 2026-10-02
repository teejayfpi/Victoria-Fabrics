import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/entities/store_settings.dart';

/// Live store settings with loading/error states intact.
final storeSettingsStreamProvider = StreamProvider<StoreSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// The current settings without the async wrapper. Falls back to the compiled
/// defaults until the document loads, so the storefront and checkout always
/// have a usable delivery fee and address rather than an empty one.
final storeSettingsProvider = Provider<StoreSettings>((ref) {
  return ref.watch(storeSettingsStreamProvider).valueOrNull ??
      const StoreSettings();
});
