import '../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../services/firestore_service.dart';
import 'guard.dart';

/// Product catalogue access.
///
/// Wraps [FirestoreService] so the presentation layer depends on an intent-named
/// API rather than raw collections, and so write operations are guarded by the
/// administrator role check.
class ProductRepository {
  ProductRepository(this._firestore);

  final FirestoreService _firestore;

  Stream<List<Product>> watchAll() => _firestore.productsStream();

  Stream<List<Product>> watchByCategory(String categoryId) {
    return _firestore
        .productsStream()
        .map((products) =>
            products.where((p) => p.categoryId == categoryId).toList());
  }

  Future<Result<Product?>> getById(String id) =>
      guard(() => _firestore.getProductById(id), tag: 'product_repo');

  Future<Result<void>> save(Product product, {required bool isNew}) {
    return guard(
      () => isNew
          ? _firestore.addProduct(product)
          : _firestore.updateProduct(product),
      tag: 'product_repo',
    );
  }

  Future<Result<void>> delete(String id) =>
      guard(() => _firestore.deleteProduct(id), tag: 'product_repo');

  Future<Result<void>> seedIfEmpty() =>
      guard(_firestore.seedProductsIfEmpty, tag: 'product_repo');
}
