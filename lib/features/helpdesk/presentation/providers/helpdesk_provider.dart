import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket_entity.dart';
import '../../../tickets/domain/entities/ticket_enum.dart';

final assignedTicketsProvider = Provider<List<TicketEntity>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final allTickets = ref.watch(ticketListProvider);

  if (currentUser == null) return [];

  return allTickets.maybeWhen(
    data: (tickets) {
      return tickets.where((t) {
        return t.assignedTo == currentUser.id ||
               t.assignedTo == currentUser.name;
      }).toList();
    },
    orElse: () => [],
  );
});

final helpdeskTicketStatsProvider = Provider<Map<String, int>>((ref) {
  final tickets = ref.watch(assignedTicketsProvider);

  return {
    'total': tickets.length,
    'open': tickets.where((t) => t.status == TicketStatus.open).length,
    'inProgress': tickets.where((t) => t.status == TicketStatus.inProgress).length,
    'pending': tickets.where((t) => t.status == TicketStatus.pending).length,
    'resolved': tickets.where((t) => t.status == TicketStatus.resolved).length,
    'closed': tickets.where((t) => t.status == TicketStatus.closed).length,
  };
});
