import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';
import 'product.dart';

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

  static OrderStatus fromString(String s) {
    switch (s) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class Order {
  final String id;
  final String? userId; // Firebase Auth UID — null for guest orders
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
    this.userId,
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

  String get statusDisplayName => status.displayName;

  String get deliveryTypeDisplayName {
    switch (deliveryType) {
      case DeliveryType.delivery:
        return 'Delivery';
      case DeliveryType.pickup:
        return 'Pickup';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      'items': items
          .map((item) => {
                'productId': item.product.id,
                'productName': item.product.name,
                'imageUrl': item.product.imageUrls.isNotEmpty
                    ? item.product.imageUrls.first
                    : '',
                'quantity': item.quantity,
                'selectedUnit': item.selectedUnit,
                'unitPrice': item.unitPrice,
                'totalPrice': item.totalPrice,
              })
          .toList(),
      'totalAmount': totalAmount,
      'deliveryType': deliveryType == DeliveryType.delivery
          ? 'delivery'
          : 'pickup',
      'deliveryAddress': deliveryAddress,
      'pickupLocation': pickupLocation,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'customerName': customerName,
      'customerPhone': customerPhone,
    };
  }

  factory Order.fromMap(String docId, Map<String, dynamic> data) {
    final rawItems =
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    DateTime createdAt;
    final rawTs = data['createdAt'];
    if (rawTs is Timestamp) {
      createdAt = rawTs.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return Order(
      id: (data['id'] as String?) ?? docId,
      userId: data['userId'] as String?,
      items: rawItems
          .map((i) => CartItem(
                product: Product.placeholder(
                  id: i['productId'] as String? ?? '',
                  name: i['productName'] as String? ?? '',
                  imageUrl: i['imageUrl'] as String? ?? '',
                ),
                quantity: (i['quantity'] as num).toInt(),
                selectedUnit: i['selectedUnit'] as String? ?? 'Yard',
              ))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      deliveryType: (data['deliveryType'] as String?) == 'pickup'
          ? DeliveryType.pickup
          : DeliveryType.delivery,
      deliveryAddress: data['deliveryAddress'] as String?,
      pickupLocation: data['pickupLocation'] as String?,
      status: OrderStatusX.fromString(data['status'] as String? ?? 'pending'),
      createdAt: createdAt,
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
    );
  }
}
