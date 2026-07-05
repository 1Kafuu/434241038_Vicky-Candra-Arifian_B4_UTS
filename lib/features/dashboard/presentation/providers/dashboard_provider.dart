import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket_entity.dart';

class DashboardSearchState {
  final String query;
  final List<TicketEntity> filteredTickets;

  DashboardSearchState({
    this.query = '',
    this.filteredTickets = const [],
  });

  DashboardSearchState copyWith({
    String? query,
    List<TicketEntity>? filteredTickets,
  }) {
    return DashboardSearchState(
      query: query ?? this.query,
      filteredTickets: filteredTickets ?? this.filteredTickets,
    );
  }
}

class DashboardSearchNotifier extends Notifier<DashboardSearchState> {
  @override
  DashboardSearchState build() {
    return DashboardSearchState();
  }

  void search(String query, List<TicketEntity> allTickets) {
    if (query.isEmpty) {
      state = DashboardSearchState(
        query: '',
        filteredTickets: [],
      );
      return;
    }

    final filtered = allTickets.where((ticket) {
      final lowerQuery = query.toLowerCase();
      return ticket.title.toLowerCase().contains(lowerQuery) ||
          ticket.description.toLowerCase().contains(lowerQuery) ||
          ticket.id.toLowerCase().contains(lowerQuery);
    }).toList();

    state = DashboardSearchState(
      query: query,
      filteredTickets: filtered,
    );
  }

  void clearSearch() {
    state = DashboardSearchState();
  }
}

final dashboardSearchProvider =
    NotifierProvider<DashboardSearchNotifier, DashboardSearchState>(() {
  return DashboardSearchNotifier();
});

final filteredTicketsProvider = Provider<List<TicketEntity>>((ref) {
  final searchState = ref.watch(dashboardSearchProvider);
  final allTickets = ref.watch(ticketListProvider);

  return allTickets.when(
    data: (tickets) {
      if (searchState.query.isEmpty) {
        return tickets;
      }
      return searchState.filteredTickets;
    },
    loading: () => <TicketEntity>[],
    error: (_, __) => <TicketEntity>[],
  );
});

final recentTicketsProvider = Provider<List<TicketEntity>>((ref) {
  final allTickets = ref.watch(ticketListProvider);

  return allTickets.when(
    data: (tickets) {
      final sorted = List<TicketEntity>.from(tickets)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted.take(4).toList();
    },
    loading: () => <TicketEntity>[],
    error: (_, __) => <TicketEntity>[],
  );
});