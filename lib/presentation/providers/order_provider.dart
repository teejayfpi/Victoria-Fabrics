import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/cart_item.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/firestore_service.dart';

// ─── Per-user Firestore order stream ─────────────────────────────────────────

/// Streams orders for the currently signed-in user.
/// Returns an empty list when no user is signed in.
final userOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.userOrdersStream(user.uid);
});

// ─── Order creation ──────────────────────────────────────────────────────────

class OrderNotifier extends StateNotifier<AsyncValue<Order?>> {
  final Ref _ref;

  OrderNotifier(this._ref) : super(const AsyncValue.data(null));

  final _uuid = const Uuid();

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
      final user = _ref.read(currentUserProvider);
      final orderId = _uuid.v4().substring(0, 8).toUpperCase();

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

      // Persist to Firestore
      await FirestoreService.instance.createOrder(order.toMap());

      state = AsyncValue.data(order);
      return order;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
