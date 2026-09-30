import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/ticket.dart';
import '../../presentation/providers/product_provider.dart';

/// A Firestore order paired with its document ID. Status writes need the
/// document ID because the customer-facing reference is only an 8-char code.
class AdminOrder {
  const AdminOrder({required this.order, required this.firestoreId});

  final Order order;
  final String firestoreId;

  factory AdminOrder.fromRow(Map<String, dynamic> row) {
    final firestoreId = row['firestoreId'] as String? ?? '';
    return AdminOrder(
      order: Order.fromMap(firestoreId, row),
      firestoreId: firestoreId,
    );
  }
}

final adminOrdersProvider = StreamProvider<List<AdminOrder>>((ref) {
  return ref.watch(orderRepositoryProvider).watchAllForAdmin(limit: 200).map(
        (rows) => rows.map(AdminOrder.fromRow).toList(),
      );
});

final adminTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return ref.watch(orderRepositoryProvider).watchTickets();
});

/// Aggregate counters shown on the admin dashboard.
class AdminStats {
  const AdminStats({
    required this.productCount,
    required this.pendingOrders,
    required this.todaySales,
    required this.openTickets,
  });

  final int productCount;
  final int pendingOrders;
  final double todaySales;
  final int openTickets;
}

final adminStatsProvider = Provider<AdminStats>((ref) {
  final products = ref.watch(allProductsProvider);
  final orders =
      ref.watch(adminOrdersProvider).valueOrNull ?? const <AdminOrder>[];
  final tickets =
      ref.watch(adminTicketsProvider).valueOrNull ?? const <SupportTicket>[];

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  final todaySales = orders
      .where((o) =>
          o.order.createdAt.isAfter(startOfDay) &&
          o.order.status != OrderStatus.cancelled)
      .fold<double>(0, (sum, o) => sum + o.order.totalAmount);

  return AdminStats(
    productCount: products.length,
    pendingOrders:
        orders.where((o) => o.order.status == OrderStatus.pending).length,
    todaySales: todaySales,
    openTickets: tickets.where((t) => t.status == 'open').length,
  );
});
