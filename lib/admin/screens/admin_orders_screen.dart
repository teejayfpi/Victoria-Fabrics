import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../../services/firestore_service.dart';

/// All orders, live from Firestore (admin view).
final _adminOrdersProvider = StreamProvider<List<AdminOrder>>((ref) {
  return FirestoreService.instance.ordersStream().map(
        (rows) => rows.map(AdminOrder.fromMap).toList(),
      );
});

/// A single order by its Firestore document id, live from Firestore.
final adminOrderByIdProvider =
    StreamProvider.family<AdminOrder?, String>((ref, firestoreId) {
  return FirestoreService.instance
      .ordersStream()
      .map((rows) {
        for (final row in rows) {
          if (row['firestoreId'] == firestoreId) {
            return AdminOrder.fromMap(row);
          }
        }
        return null;
      });
});

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => AdminOrdersScreenState();
}

class AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Preparing'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OrdersList(filterStatus: null),
          _OrdersList(filterStatus: OrderStatus.pending),
          _OrdersList(filterStatus: OrderStatus.confirmed),
          _OrdersList(filterStatus: OrderStatus.preparing),
          _OrdersList(filterStatus: OrderStatus.delivered),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final OrderStatus? filterStatus;

  const _OrdersList({this.filterStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_adminOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Could not load orders',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(_adminOrdersProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (orders) {
        final filtered = filterStatus == null
            ? orders
            : orders.where((o) => o.status == filterStatus).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long,
                    size: 80,
                    color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  filterStatus == null
                      ? 'No orders yet'
                      : 'No ${filterStatus!.displayName.toLowerCase()} orders',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final order = filtered[index];
            return _OrderCard(
              order: order,
              onStatusUpdate: (firestoreId, newStatus) =>
                  _updateStatus(context, firestoreId, newStatus),
            );
          },
        );
      },
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

/// Adapter over the Firestore [Order] entity.
///
/// Carries both the Firestore document id (needed to write a status update)
/// and the customer-facing order id (shown in the UI).
class AdminOrder {
  final String firestoreId;
  final Order order;

  const AdminOrder({required this.firestoreId, required this.order});

  String get id => order.id;
  String get customerName => order.customerName;
  String get customerPhone => order.customerPhone;
  int get items => order.items.length;
  double get total => order.totalAmount;
  OrderStatus get status => order.status;
  DateTime get createdAt => order.createdAt;
  DeliveryType get deliveryType => order.deliveryType;
  String get address =>
      order.deliveryType == DeliveryType.pickup
          ? (order.pickupLocation ?? 'Pickup')
          : (order.deliveryAddress ?? '');

  factory AdminOrder.fromMap(Map<String, dynamic> data) {
    final firestoreId = data['firestoreId'] as String? ?? '';
    return AdminOrder(
      firestoreId: firestoreId,
      order: Order.fromMap(firestoreId, data),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final void Function(String orderId, OrderStatus newStatus) onStatusUpdate;

  const _OrderCard({required this.order, required this.onStatusUpdate});

  Color _getStatusColor() {
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
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/admin/orders/${order.firestoreId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.displayName.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(order.customerName,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(order.customerPhone,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.shopping_bag,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${order.items} items'),
                  const SizedBox(width: 16),
                  const Icon(Icons.local_shipping,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(order.deliveryType == DeliveryType.delivery
                      ? 'Delivery'
                      : 'Pickup'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dateFormat.format(order.createdAt),
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(color: Colors.grey)),
                  Text(
                    '₦${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push('/admin/orders/${order.firestoreId}'),
                      child: const Text('View Details'),
                    ),
                  ),
                  if (order.status == OrderStatus.pending) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onStatusUpdate(order.firestoreId, OrderStatus.confirmed);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Order confirmed!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                  if (order.status == OrderStatus.confirmed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onStatusUpdate(order.firestoreId, OrderStatus.preparing);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Preparing order!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple),
                        child: const Text('Start Preparing'),
                      ),
                    ),
                  ],
                  if (order.status == OrderStatus.preparing ||
                      order.status == OrderStatus.ready) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onStatusUpdate(order.firestoreId, OrderStatus.delivered);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Order marked as delivered!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text('Mark Delivered'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
