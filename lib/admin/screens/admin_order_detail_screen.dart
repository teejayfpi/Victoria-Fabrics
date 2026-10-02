import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../presentation/widgets/product_image.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_data_providers.dart';

/// Full detail for a single order, reached by tapping a row on the orders list.
///
/// Replaces the previous "coming soon" placeholder. Staff can inspect every
/// line, the delivery details and the customer contact, advance the status, and
/// jump to WhatsApp or the dialler to reach the customer.
class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  /// Firestore document id — what status writes need.
  final String orderId;

  /// The row passed through navigation, so the screen renders immediately
  /// instead of flashing a spinner while the stream catches up.
  final AdminOrder? initialOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamed = ref.watch(adminOrdersProvider).valueOrNull;
    final order =
        streamed?.where((o) => o.firestoreId == orderId).firstOrNull ??
            initialOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This order could not be found. It may have been removed.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.order.reference),
        actions: [
          IconButton(
            tooltip: 'Copy order ID',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: order.order.reference));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order ID copied')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(adminOrder: order),
          const SizedBox(height: 16),
          _Section(
            title: 'Items (${order.order.items.length})',
            child: Column(
              children: [
                for (var i = 0; i < order.order.items.length; i++) ...[
                  if (i > 0) const Divider(height: 24),
                  _LineItem(item: order.order.items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Customer',
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: order.order.customerName,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: order.order.customerPhone,
                  actions: [
                    IconButton(
                      tooltip: 'Call',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.call, size: 20),
                      onPressed: () => _open(
                        context,
                        Uri(scheme: 'tel', path: order.order.customerPhone),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Delivery',
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.local_shipping,
                  label: 'Method',
                  value: order.order.deliveryTypeDisplayName,
                ),
                if (order.order.deliveryAddress != null &&
                    order.order.deliveryAddress!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: order.order.deliveryAddress!,
                  ),
                ],
                if (order.order.pickupLocation != null &&
                    order.order.pickupLocation!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.store,
                    label: 'Pickup at',
                    value: order.order.pickupLocation!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Summary',
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Placed',
                  value: DateFormat('MMM dd, yyyy • hh:mm a')
                      .format(order.order.createdAt),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.tag,
                  label: 'Document ID',
                  value: order.firestoreId,
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '₦${order.order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the app.')),
      );
    }
  }
}

/// Status badge plus the next-step action, mirroring the orders list.
class _StatusCard extends ConsumerStatefulWidget {
  const _StatusCard({required this.adminOrder});

  final AdminOrder adminOrder;

  @override
  ConsumerState<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends ConsumerState<_StatusCard> {
  bool _updating = false;

  Color _color(OrderStatus status) => switch (status) {
        OrderStatus.pending => Colors.orange,
        OrderStatus.confirmed => Colors.blue,
        OrderStatus.preparing => Colors.purple,
        OrderStatus.ready => Colors.teal,
        OrderStatus.delivered => Colors.green,
        OrderStatus.cancelled => Colors.red,
      };

  (String, OrderStatus, Color)? get _nextAction =>
      switch (widget.adminOrder.order.status) {
        OrderStatus.pending => ('Confirm', OrderStatus.confirmed, Colors.blue),
        OrderStatus.confirmed => (
            'Start Preparing',
            OrderStatus.preparing,
            Colors.purple
          ),
        OrderStatus.preparing || OrderStatus.ready => (
            'Mark Delivered',
            OrderStatus.delivered,
            Colors.green
          ),
        OrderStatus.delivered || OrderStatus.cancelled => null,
      };

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
          tag: 'admin_orders', context: {'status': newStatus.name});
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
    final status = widget.adminOrder.order.status;
    final color = _color(status);
    final action = _nextAction;

    return _Section(
      title: 'Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
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
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: ProductImage(
                imageUrl: item.product.imageUrls.firstOrNull ?? ''),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} × ${item.selectedUnit} · '
                '₦${item.unitPrice.toStringAsFixed(0)} each',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₦${item.totalPrice.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actions = const [],
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}
