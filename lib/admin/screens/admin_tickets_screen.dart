import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/ticket.dart';
import '../../services/firestore_service.dart';

final _ticketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return FirestoreService.instance.ticketsStream();
});

class AdminTicketsScreen extends ConsumerStatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  ConsumerState<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends ConsumerState<AdminTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(_ticketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tickets) {
          final open = tickets.where((t) => t.status == 'open').toList();
          final inProgress =
              tickets.where((t) => t.status == 'in_progress').toList();
          final resolved =
              tickets.where((t) => t.status == 'resolved').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _TicketList(tickets: open, emptyLabel: 'No open tickets'),
              _TicketList(
                  tickets: inProgress, emptyLabel: 'No in-progress tickets'),
              _TicketList(
                  tickets: resolved, emptyLabel: 'No resolved tickets'),
            ],
          );
        },
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<SupportTicket> tickets;
  final String emptyLabel;

  const _TicketList({required this.tickets, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  const _TicketCard({required this.ticket});

  Color _statusColor() {
    switch (ticket.status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (ticket.status) {
      case 'open':
        return 'OPEN';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'resolved':
        return 'RESOLVED';
      default:
        return ticket.status.toUpperCase();
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await FirestoreService.instance.updateTicketStatus(ticket.id, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket marked as ${newStatus.replaceAll('_', ' ')}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final color = _statusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.confirmation_number,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer info
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(ticket.customerName,
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(ticket.customerPhone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),

            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                ticket.message,
                style: const TextStyle(height: 1.5, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),

            // Date
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(ticket.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20),

            // Action buttons
            Row(
              children: [
                if (ticket.status == 'open') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateStatus(context, 'in_progress'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text('Start Working'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (ticket.status == 'in_progress') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateStatus(context, 'resolved'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('Mark Resolved'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (ticket.status != 'open')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, 'open'),
                      child: const Text('Reopen'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
