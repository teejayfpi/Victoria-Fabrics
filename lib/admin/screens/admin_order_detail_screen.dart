import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state.dart';
import '../../domain/entities/order.dart';
import '../../services/firestore_service.dart';
import 'admin_orders_screen.dart';

/// Full detail view for a single order, keyed by Firestore document id.
class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(adminOrderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          title: 'Could not load order',
          error: error,
          onRetry: () => ref.invalidate(adminOrderByIdProvider(orderId)),
        ),
        data: (adminOrder) {
          if (adminOrder == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Order not found',
              message: 'This order may have been deleted.',
            );
          }

          final order = adminOrder.order;
          final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
          final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(order: adminOrder),
                const SizedBox(height: 24),

                const _SectionTitle('Customer'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(order.customerName.isEmpty
                            ? 'Unnamed customer'
                            : order.customerName),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(order.customerPhone.isEmpty
                            ? 'No phone provided'
                            : order.customerPhone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const _SectionTitle('Delivery'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              order.deliveryType == DeliveryType.delivery
                                  ? 'Delivery'
                                  : 'Pickup',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          adminOrder.address.isEmpty
                              ? 'No address provided'
                              : adminOrder.address,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _SectionTitle('Items (${order.items.length})'),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < order.items.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          title: Text(order.items[i].product.name),
                          subtitle: Text(
                            '${order.items[i].quantity} '
                            '${order.items[i].selectedUnit} × '
                            '${currency.format(order.items[i].unitPrice)}',
                          ),
                          trailing: Text(
                            currency.format(order.items[i].totalPrice),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          currency.format(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const _SectionTitle('Update Status'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in OrderStatus.values)
                          ChoiceChip(
                            label: Text(status.displayName),
                            selected: order.status == status,
                            onSelected: (_) => _updateStatus(
                                context, adminOrder.firestoreId, status),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const _SectionTitle('Placed'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(dateFormat.format(order.createdAt)),
                  ),
                ),
                const SizedBox(height: 24),

                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Orders'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, String firestoreId, OrderStatus newStatus) async {
    try {
      await FirestoreService.instance
          .updateOrderStatus(firestoreId, newStatus.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked ${newStatus.displayName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  final AdminOrder order;

  const _Header({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            order.id,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            order.status.displayName.toUpperCase(),
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textColor,
        ),
      ),
    );
  }
}