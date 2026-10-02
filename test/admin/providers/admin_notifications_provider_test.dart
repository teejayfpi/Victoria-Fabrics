import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/admin/providers/admin_data_providers.dart';
import 'package:fabric_haven/admin/providers/admin_notifications_provider.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/order.dart';
import 'package:fabric_haven/domain/entities/product.dart';
import 'package:fabric_haven/domain/entities/ticket.dart';

Product _product() => const Product(
      id: 'p1',
      name: 'Ankara',
      description: 'desc',
      categoryId: 'c1',
      categoryName: 'Ankara',
      imageUrls: [],
      pricePerYard: 1000,
      pricePerMeter: 1000,
      pricePerPiece: 1000,
      inStock: true,
      colors: [],
      availableUnits: ['Yard'],
    );

AdminOrder _order({
  required String firestoreId,
  required DateTime createdAt,
  required String customerName,
  OrderStatus status = OrderStatus.pending,
}) {
  return AdminOrder(
    firestoreId: firestoreId,
    order: Order(
      id: firestoreId.substring(0, 8).toUpperCase(),
      items: [
        CartItem(
          product: _product(),
          quantity: 1,
          selectedUnit: 'Yard',
        ),
      ],
      totalAmount: 1000,
      deliveryType: DeliveryType.delivery,
      status: status,
      createdAt: createdAt,
      customerName: customerName,
      customerPhone: '08000000000',
    ),
  );
}

SupportTicket _ticket({
  required String id,
  required DateTime createdAt,
  String status = 'open',
}) {
  return SupportTicket(
    id: id,
    customerName: 'Ada',
    customerPhone: '08000000000',
    subject: 'Where is my order?',
    message: 'Please help',
    status: status,
    createdAt: createdAt,
  );
}

void main() {
  group('buildAdminNotifications', () {
    final now = DateTime(2026, 5, 20, 12, 0, 0);

    test('returns nothing when there are no orders or tickets', () {
      expect(
        buildAdminNotifications(orders: const [], tickets: const []),
        isEmpty,
      );
    });

    test('derives a notification per order with a deep link', () {
      final result = buildAdminNotifications(
        orders: [
          _order(
            firestoreId: 'abcdef1234567890',
            createdAt: now,
            customerName: 'Chidi',
          ),
        ],
        tickets: const [],
      );

      expect(result, hasLength(1));
      expect(result.single.kind, AdminNotificationKind.order);
      expect(result.single.title, contains('VF-ABCDEF12'));
      expect(result.single.subtitle, 'Chidi');
      expect(result.single.route, '/admin/orders/abcdef1234567890');
    });

    test('includes only open tickets', () {
      final result = buildAdminNotifications(
        orders: const [],
        tickets: [
          _ticket(id: 't1', createdAt: now),
          _ticket(id: 't2', createdAt: now, status: 'resolved'),
        ],
      );

      expect(result, hasLength(1));
      expect(result.single.kind, AdminNotificationKind.ticket);
      expect(result.single.route, '/admin/tickets');
    });

    test('sorts newest first and honours the limit', () {
      final result = buildAdminNotifications(
        orders: [
          _order(
            firestoreId: 'older000',
            createdAt: now.subtract(const Duration(hours: 2)),
            customerName: 'Older',
          ),
          _order(
            firestoreId: 'newer000',
            createdAt: now,
            customerName: 'Newer',
          ),
        ],
        tickets: const [],
        limit: 2,
      );

      expect(result, hasLength(2));
      expect(result.first.subtitle, 'Newer');
      expect(result.last.subtitle, 'Older');
    });

    test('drops the oldest entries once the limit is reached', () {
      final result = buildAdminNotifications(
        orders: [
          _order(
            firestoreId: 'older000',
            createdAt: now.subtract(const Duration(hours: 2)),
            customerName: 'Older',
          ),
          _order(
            firestoreId: 'newer000',
            createdAt: now,
            customerName: 'Newer',
          ),
        ],
        tickets: const [],
        limit: 1,
      );

      expect(result, hasLength(1));
      expect(result.single.subtitle, 'Newer');
    });
  });
}
