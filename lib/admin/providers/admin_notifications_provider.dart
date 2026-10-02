import '../../domain/entities/ticket.dart';
import 'admin_data_providers.dart';

enum AdminNotificationKind { order, ticket }

/// A single dashboard notification, derived from live order/ticket data.
class AdminNotification {
  const AdminNotification({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.route,
  });

  final AdminNotificationKind kind;
  final String title;
  final String subtitle;
  final DateTime createdAt;

  /// Where tapping the notification should take the administrator.
  final String? route;
}

/// Builds the notification feed from the newest orders and open tickets.
///
/// Pure and order-stable (newest first) so it can be unit-tested; the previous
/// implementation showed hardcoded "New Order received / 2 minutes ago" rows
/// that never reflected the store.
List<AdminNotification> buildAdminNotifications({
  required List<AdminOrder> orders,
  required List<SupportTicket> tickets,
  int limit = 20,
}) {
  final items = <AdminNotification>[
    for (final adminOrder in orders)
      AdminNotification(
        kind: AdminNotificationKind.order,
        title: '${adminOrder.order.reference} · '
            '${adminOrder.order.statusDisplayName}',
        subtitle: adminOrder.order.customerName.isEmpty
            ? 'New order'
            : adminOrder.order.customerName,
        createdAt: adminOrder.order.createdAt,
        route: '/admin/orders/${adminOrder.firestoreId}',
      ),
    for (final ticket in tickets)
      if (ticket.status == 'open')
        AdminNotification(
          kind: AdminNotificationKind.ticket,
          title: 'Support: ${ticket.subject}',
          subtitle: ticket.customerName.isEmpty
              ? 'Open ticket'
              : ticket.customerName,
          createdAt: ticket.createdAt,
          route: '/admin/tickets',
        ),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return items.take(limit).toList();
}
