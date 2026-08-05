import 'cart_item.dart';

enum DeliveryType { delivery, pickup }

enum OrderStatus { pending, confirmed, preparing, ready, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DeliveryType deliveryType;
  final String? deliveryAddress;
  final String? pickupLocation;
  final OrderStatus status;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;

  const Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.deliveryType,
    this.deliveryAddress,
    this.pickupLocation,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
  });

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get deliveryTypeDisplayName {
    switch (deliveryType) {
      case DeliveryType.delivery:
        return 'Delivery';
      case DeliveryType.pickup:
        return 'Pickup';
    }
  }
}