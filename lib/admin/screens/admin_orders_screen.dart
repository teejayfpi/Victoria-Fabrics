import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
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
        children: [
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

class _OrdersList extends StatefulWidget {
  final OrderStatus? filterStatus;

  const _OrdersList({this.filterStatus});

  @override
  State<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<_OrdersList> {
  late List<_AdminOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _buildOrders();
  }

  List<_AdminOrder> _buildOrders() {
    final all = [
      _AdminOrder(
        id: 'ORD-001',
        customerName: 'Adebayo Johnson',
        customerPhone: '08012345678',
        items: 3,
        total: 125000,
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        deliveryType: DeliveryType.delivery,
        address: '15 Admiralty Way, Lekki Phase 1, Lagos',
      ),
      _AdminOrder(
        id: 'ORD-002',
        customerName: 'Chioma Adekunle',
        customerPhone: '08123456789',
        items: 5,
        total: 245000,
        status: OrderStatus.confirmed,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        deliveryType: DeliveryType.pickup,
        address: 'Victoria Fabrics Store, Lagos',
      ),
      _AdminOrder(
        id: 'ORD-003',
        customerName: 'Emmanuel Obi',
        customerPhone: '08098765432',
        items: 2,
        total: 45000,
        status: OrderStatus.preparing,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        deliveryType: DeliveryType.delivery,
        address: '25 Ajah Road, Ajah, Lagos',
      ),
      _AdminOrder(
        id: 'ORD-004',
        customerName: 'Fatima Ibrahim',
        customerPhone: '08123412341',
        items: 4,
        total: 180000,
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        deliveryType: DeliveryType.pickup,
        address: 'Victoria Fabrics Store, Lagos',
      ),
      _AdminOrder(
        id: 'ORD-005',
        customerName: 'Olumide Santos',
        customerPhone: '08055555555',
        items: 1,
        total: 22000,
        status: OrderStatus.delivered,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        deliveryType: DeliveryType.delivery,
        address: '10 Victoria Island, Lagos',
      ),
    ];

    if (widget.filterStatus == null) return all;
    return all.where((o) => o.status == widget.filterStatus).toList();
  }

  void _updateOrderStatus(String orderId, OrderStatus newStatus) {
    setState(() {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No orders found',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _OrderCard(
          order: order,
          onStatusUpdate: _updateOrderStatus,
        );
      },
    );
  }
}

class _AdminOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final int items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DeliveryType deliveryType;
  final String address;

  _AdminOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.deliveryType,
    required this.address,
  });

  _AdminOrder copyWith({OrderStatus? status}) {
    return _AdminOrder(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
      deliveryType: deliveryType,
      address: address,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _AdminOrder order;
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
        onTap: () => context.push('/admin/orders/${order.id}'),
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
                          context.push('/admin/orders/${order.id}'),
                      child: const Text('View Details'),
                    ),
                  ),
                  if (order.status == OrderStatus.pending) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onStatusUpdate(order.id, OrderStatus.confirmed);
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
                          onStatusUpdate(order.id, OrderStatus.preparing);
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
                          onStatusUpdate(order.id, OrderStatus.delivered);
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
