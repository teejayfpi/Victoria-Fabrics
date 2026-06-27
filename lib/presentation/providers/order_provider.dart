import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_provider.dart';

class OrderNotifier extends StateNotifier<List<Order>> {
  OrderNotifier() : super([]);

  final _uuid = const Uuid();

  void createOrder({
    required List<CartItem> items,
    required double totalAmount,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    required String customerName,
    required String customerPhone,
  }) {
    final order = Order(
      id: _uuid.v4().substring(0, 8).toUpperCase(),
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

    state = [order, ...state];
    print('[Fabric Haven] Order created: ${order.id}');
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<Order>>((ref) {
  return OrderNotifier();
});

final latestOrderProvider = Provider<Order?>((ref) {
  final orders = ref.watch(orderProvider);
  return orders.isNotEmpty ? orders.first : null;
});