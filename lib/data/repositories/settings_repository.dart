import '../../core/error/failures.dart';
import '../../domain/entities/store_settings.dart';
import '../../services/firestore_service.dart';
import 'guard.dart';

/// Owner-editable store settings (delivery fee, shop address, contacts).
///
/// Reads come from the world-readable `settings/store` document; writes are
/// guarded by the administrator role check and, ultimately, by the security
/// rules that allow only staff to write it.
class SettingsRepository {
  SettingsRepository(this._firestore);

  final FirestoreService _firestore;

  Stream<StoreSettings> watch() => _firestore.storeSettingsStream();

  Future<Result<void>> save(StoreSettings settings) =>
      guard(() => _firestore.saveStoreSettings(settings), tag: 'settings_repo');
}
