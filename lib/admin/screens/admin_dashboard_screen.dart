import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/error/error_mapper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/async_state.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/ticket.dart';
import '../../presentation/providers/product_provider.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_data_providers.dart';
import '../providers/admin_notifications_provider.dart';

/// Formats a naira amount compactly for the stat tiles, e.g. `₦1.2M`.
String _compactCurrency(double amount) {
  if (amount >= 1000000) {
    return '₦${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 1000) {
    return '₦${(amount / 1000).toStringAsFixed(1)}K';
  }
  return '₦${amount.toStringAsFixed(0)}';
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminAuthProvider);
    final admin = adminState.valueOrNull;
    final stats = ref.watch(adminStatsProvider);
    // Distinguish "the store has no data" from "the read failed". Without this
    // the tiles and the recent-orders list silently show zeros and an empty
    // card, which reads as a broken dashboard.
    final loadError = ref.watch(adminOrdersProvider).error ??
        ref.watch(adminTicketsProvider).error ??
        ref.watch(allProductsStreamProvider).error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context, ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push('/admin/profile');
                case 'settings':
                  context.push('/admin/settings');
                case 'logout':
                  ref.read(adminAuthProvider.notifier).logout();
                  context.go('/admin/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin?.name ?? 'Admin',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    Text(admin?.email ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Store Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: loadError != null
          ? AppErrorState(
              title: 'Could not load dashboard data',
              message:
                  ErrorMapper.map(loadError, StackTrace.current).message,
              onRetry: () {
                ref.invalidate(adminOrdersProvider);
                ref.invalidate(adminTicketsProvider);
                ref.invalidate(allProductsStreamProvider);
              },
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.75)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${admin?.name ?? 'Admin'}!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Here's what's happening with Victoria Fabrics today.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            const Text('Overview',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _StatCard(
                    title: 'Total Products',
                    value: '${stats.productCount}',
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                    onTap: () => context.push('/admin/products')),
                _StatCard(
                    title: 'Pending Orders',
                    value: '${stats.pendingOrders}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    onTap: () => context.push('/admin/orders')),
                _StatCard(
                    title: "Today's Sales",
                    value: _compactCurrency(stats.todaySales),
                    icon: Icons.trending_up,
                    color: Colors.green,
                    onTap: () => context.push('/admin/analytics')),
                _StatCard(
                    title: 'Open Tickets',
                    value: '${stats.openTickets}',
                    icon: Icons.confirmation_number,
                    color: Colors.purple,
                    onTap: () => context.push('/admin/tickets')),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_circle,
                    title: 'Add Product',
                    color: Colors.blue,
                    onTap: () =>
                        context.push('/admin/products/add'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long,
                    title: 'View Orders',
                    color: Colors.orange,
                    onTap: () => context.push('/admin/orders'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.confirmation_number,
                    title: 'Tickets',
                    color: Colors.purple,
                    onTap: () => context.push('/admin/tickets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    color: Colors.green,
                    onTap: () =>
                        context.push('/admin/analytics'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.inventory_2,
                    title: 'Products',
                    color: Colors.indigo,
                    onTap: () => context.push('/admin/products'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.settings,
                    title: 'Store Settings',
                    color: Colors.teal,
                    onTap: () => context.push('/admin/settings'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent orders placeholder
            const Text('Recent Orders',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
            const SizedBox(height: 12),
            const _RecentOrdersList(),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final orders =
        ref.read(adminOrdersProvider).valueOrNull ?? const <AdminOrder>[];
    final tickets =
        ref.read(adminTicketsProvider).valueOrNull ?? const <SupportTicket>[];
    final notifications = buildAdminNotifications(
      orders: orders,
      tickets: tickets,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notifications',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('Nothing new right now',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (ctx, i) {
                      final n = notifications[i];
                      final isOrder =
                          n.kind == AdminNotificationKind.order;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isOrder ? Colors.orange : Colors.purple,
                          child: Icon(
                            isOrder
                                ? Icons.receipt_long
                                : Icons.confirmation_number,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(n.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${n.subtitle} · '
                          '${formatRelativeTime(n.createdAt)}',
                        ),
                        onTap: n.route == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                context.push(n.route!);
                              },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey[400]),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(title,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrdersList extends ConsumerWidget {
  const _RecentOrdersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminOrdersProvider);
    final recent = (async.valueOrNull ?? const <AdminOrder>[])
        .take(3)
        .toList();

    return Card(
      child: Column(
        children: [
          if (recent.isEmpty)
            const ListTile(
              title: Text('No orders yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _OrderTile(adminOrder: recent[i]),
            ],
          const Divider(height: 1),
          ListTile(
            onTap: () => context.push('/admin/orders'),
            title: const Text('View all orders →',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.adminOrder});

  final AdminOrder adminOrder;

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

  @override
  Widget build(BuildContext context) {
    final order = adminOrder.order;
    final statusColor = _statusColor(order.status);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: const Icon(Icons.receipt,
            color: AppTheme.primaryColor, size: 18),
      ),
      title: Text(order.reference,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(order.customerName),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('₦${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(order.status.displayName,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      onTap: () => context.push(
        '/admin/orders/${adminOrder.firestoreId}',
        extra: adminOrder,
      ),
    );
  }
}
