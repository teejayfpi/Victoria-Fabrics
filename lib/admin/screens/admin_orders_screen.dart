import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_data_providers.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = <(String, OrderStatus?)>[
    ('All', null),
    ('Pending', OrderStatus.pending),
    ('Confirmed', OrderStatus.confirmed),
    ('Preparing', OrderStatus.preparing),
    ('Delivered', OrderStatus.delivered),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
          tabs: [for (final (label, _) in _tabs) Tab(text: label)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final (_, status) in _tabs) _OrdersList(filterStatus: status),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({this.filterStatus});

  final OrderStatus? filterStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminOrdersProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _OrdersErrorState(
        message: ErrorMapper.map(error, stack).message,
        onRetry: () => ref.invalidate(adminOrdersProvider),
      ),
      data: (orders) {
        final filtered = filterStatus == null
            ? orders
            : orders.where((o) => o.order.status == filterStatus).toList();

        if (filtered.isEmpty) {
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

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminOrdersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) =>
                _OrderCard(adminOrder: filtered[index]),
          ),
        );
      },
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  const _OrdersErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.adminOrder});

  final AdminOrder adminOrder;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _updating = false;

  Color _statusColor(OrderStatus status) {
    switch (status) {
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

  /// The single status transition available from the current state, if any.
  (String, OrderStatus, Color)? get _nextAction {
    switch (widget.adminOrder.order.status) {
      case OrderStatus.pending:
        return ('Confirm', OrderStatus.confirmed, Colors.blue);
      case OrderStatus.confirmed:
        return ('Start Preparing', OrderStatus.preparing, Colors.purple);
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return ('Mark Delivered', OrderStatus.delivered, Colors.green);
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }

  Future<void> _advance(OrderStatus newStatus) async {
    setState(() => _updating = true);
    try {
      requireAdmin(ref.read(currentAdminProvider), minimum: AdminRole.staff);
      final result = await ref.read(orderRepositoryProvider).updateOrderStatus(
            widget.adminOrder.firestoreId,
            newStatus.name,
          );
      result.fold(
        onSuccess: (_) {},
        onError: (failure) => throw Exception(failure.message),
      );
      AppLogger.info('Order status updated',
          tag: 'admin_orders',
          context: {'status': newStatus.name});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked ${newStatus.displayName}')),
        );
      }
    } catch (e, st) {
      AppLogger.error('Order status update failed',
          tag: 'admin_orders', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.map(e, st).message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.adminOrder.order;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final color = _statusColor(order.status);
    final action = _nextAction;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.reference,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.displayName.toUpperCase(),
                    style: TextStyle(
                      color: color,
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
                Expanded(
                  child: Text(order.customerName,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order.customerPhone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${order.items.length} items'),
                const SizedBox(width: 16),
                const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order.deliveryTypeDisplayName),
              ],
            ),
            if (order.deliveryAddress != null &&
                order.deliveryAddress!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(order.deliveryAddress!,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dateFormat.format(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(color: Colors.grey)),
                Text(
                  '₦${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updating ? null : () => _advance(action.$2),
                  style: ElevatedButton.styleFrom(backgroundColor: action.$3),
                  child: _updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(action.$1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
