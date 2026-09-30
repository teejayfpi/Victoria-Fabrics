import '../../core/error/failures.dart';
import '../../core/validation/validators.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/ticket.dart';
import '../../services/firestore_service.dart';
import 'guard.dart';

/// Order and support-ticket access.
class OrderRepository {
  OrderRepository(this._firestore);

  final FirestoreService _firestore;

  Stream<List<Order>> watchForUser(String uid) =>
      _firestore.userOrdersStream(uid);

  Stream<List<Map<String, dynamic>>> watchAllForAdmin({int limit = 100}) =>
      _firestore.ordersStream(limit: limit);

  Stream<List<SupportTicket>> watchTickets({int limit = 200}) =>
      _firestore.ticketsStream(limit: limit);

  /// Places an order. Prices, stock and the total are re-derived inside the
  /// Firestore transaction; the client-supplied [expectedTotal] is only used
  /// to detect a stale cart.
  Future<Result<String>> placeOrder({
    required List<CartItem> items,
    required double expectedTotal,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    required String customerName,
    required String customerPhone,
  }) {
    return guard(
      () => _firestore.createOrder(
        items: items,
        expectedTotal: expectedTotal,
        deliveryType: deliveryType,
        deliveryAddress: deliveryType == DeliveryType.delivery
            ? deliveryAddress?.trim()
            : null,
        pickupLocation: pickupLocation,
        customerName: customerName.trim(),
        customerPhone: Validators.normalisePhone(customerPhone),
      ),
      tag: 'order_repo',
    );
  }

  Future<Result<void>> updateOrderStatus(String firestoreId, String status) =>
      guard(
        () => _firestore.updateOrderStatus(firestoreId, status),
        tag: 'order_repo',
      );

  Future<Result<void>> submitTicket(SupportTicket ticket) =>
      guard(() => _firestore.submitTicket(ticket), tag: 'ticket_repo');

  Future<Result<void>> updateTicketStatus(String id, String status) =>
      guard(
        () => _firestore.updateTicketStatus(id, status),
        tag: 'ticket_repo',
      );
}
