import '../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../services/firestore_service.dart';
import 'guard.dart';

/// Category catalogue access.
///
/// Mirrors [ProductRepository]: read streams for the storefront and
/// role-guarded writes for the admin app.
class CategoryRepository {
  CategoryRepository(this._firestore);

  final FirestoreService _firestore;

  Stream<List<Category>> watchAll() => _firestore.categoriesStream();

  Future<Result<void>> save(Category category, {required bool isNew}) {
    return guard(
      () => isNew
          ? _firestore.addCategory(category)
          : _firestore.updateCategory(category),
      tag: 'category_repo',
    );
  }

  Future<Result<void>> delete(String id) =>
      guard(() => _firestore.deleteCategory(id), tag: 'category_repo');

  Future<Result<void>> seedIfEmpty() =>
      guard(_firestore.seedCategoriesIfEmpty, tag: 'category_repo');
}
