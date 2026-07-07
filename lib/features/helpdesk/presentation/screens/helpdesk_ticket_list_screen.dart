import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../providers/helpdesk_provider.dart';

class HelpdeskTicketListScreen extends ConsumerWidget {
  const HelpdeskTicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(assignedTicketsProvider);
    final stats = ref.watch(helpdeskTicketStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiket Ditugaskan'),
        backgroundColor: isDark ? Colors.grey.shade900 : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Total', count: stats['total'] ?? 0),
                _StatItem(label: 'Open', count: stats['open'] ?? 0, color: Colors.blue),
                _StatItem(label: 'Progress', count: stats['inProgress'] ?? 0, color: Colors.orange),
                _StatItem(label: 'Resolved', count: stats['resolved'] ?? 0, color: Colors.green),
              ],
            ),
          ),
          Expanded(
            child: tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada tiket yang ditugaskan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.read(ticketListProvider.notifier).refresh();
                    },
                    child: ListView.builder(
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: StatusBadge(status: ticket.status.label),
                            title: Text(ticket.title),
                            subtitle: Text(
                              ticket.description.length > 50
                                  ? '${ticket.description.substring(0, 50)}...'
                                  : ticket.description,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TicketDetailScreen(ticket: ticket),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
