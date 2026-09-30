import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/cart_item.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_mapper.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';

// ─── Per-user Firestore order stream ─────────────────────────────────────────

/// Streams orders for the currently signed-in user.
/// Returns an empty list when no user is signed in.
final userOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream<List<Order>>.empty();
  return ref.watch(orderRepositoryProvider).watchForUser(user.uid);
});

// ─── Order creation ──────────────────────────────────────────────────────────

class OrderNotifier extends StateNotifier<AsyncValue<Order?>> {
  final Ref _ref;

  OrderNotifier(this._ref) : super(const AsyncValue.data(null));

  final _uuid = const Uuid();

  /// Creates an order. Validation happens in two places: here (fast feedback
  /// before a network round-trip) and inside the Firestore transaction, which
  /// is the authoritative check for price and stock.
  Future<Order?> createOrder({
    required List<CartItem> items,
    required double totalAmount,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    required String customerName,
    required String customerPhone,
  }) async {
    state = const AsyncValue.loading();

    try {
      if (items.isEmpty) {
        throw StateError('Your cart is empty.');
      }
      if (deliveryType == DeliveryType.delivery &&
          (deliveryAddress == null || deliveryAddress.trim().isEmpty)) {
        throw StateError('A delivery address is required.');
      }

      final user = _ref.read(currentUserProvider);
      final orderId = _uuid.v4().substring(0, 8).toUpperCase();

      // Persist through the repository — the underlying transaction re-derives
      // the total and stock server-side.
      final result = await _ref.read(orderRepositoryProvider).placeOrder(
            items: items,
            expectedTotal: totalAmount,
            deliveryType: deliveryType,
            deliveryAddress: deliveryAddress,
            pickupLocation: pickupLocation,
            customerName: customerName,
            customerPhone: customerPhone,
            userId: user?.uid,
          );

      final docId = result.fold(
        onSuccess: (id) => id,
        onError: (failure) => throw AppException(
          message: failure.message,
          code: failure.code,
        ),
      );

      final order = Order(
        id: orderId,
        userId: user?.uid,
        items: items,
        totalAmount: totalAmount,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        pickupLocation: pickupLocation,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        customerName: customerName,
        customerPhone: customerPhone,
      );

      AppLogger.info('Order placed', tag: 'orders', context: {'docId': docId});
      state = AsyncValue.data(order);
      return order;
    } catch (e, st) {
      AppLogger.error('Order creation failed', tag: 'orders', error: e);
      state = AsyncValue.error(ErrorMapper.map(e, st), st);
      rethrow;
    }
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<Order?>>((ref) {
  return OrderNotifier(ref);
});

/// Latest placed order (used by the confirmation screen)
final latestOrderProvider = Provider<Order?>((ref) {
  return ref.watch(orderNotifierProvider).valueOrNull;
});

// ─── Legacy alias (kept so existing screens don't break) ─────────────────────
/// Convenience: current user's orders as a plain list (empty until loaded / signed in)
final orderProvider = Provider<List<Order>>((ref) {
  return ref.watch(userOrdersStreamProvider).valueOrNull ?? [];
});
