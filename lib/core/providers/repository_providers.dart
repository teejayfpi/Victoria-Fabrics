import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/firestore_service.dart';

/// Single Firestore-backed instance shared by every repository.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(firestoreServiceProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(firestoreServiceProvider));
});
