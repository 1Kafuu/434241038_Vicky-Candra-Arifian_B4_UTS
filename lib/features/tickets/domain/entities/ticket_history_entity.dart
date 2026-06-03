class TicketHistoryEntity {
  final String id;
  final String ticketId;
  final String action;
  final String description;
  final String updatedBy;       // UUID actor
  final String updatedByName;   // nama actor (dari join profiles)
  final DateTime timestamp;

  const TicketHistoryEntity({
    required this.id,
    required this.ticketId,
    required this.action,
    required this.description,
    required this.updatedBy,
    required this.updatedByName,
    required this.timestamp,
  });
}
