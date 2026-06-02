class TicketHistoryEntity {
  final String id;
  final String ticketId;
  final String changedBy;
  final String? oldStatus;
  final String newStatus;
  final DateTime createdAt;

  const TicketHistoryEntity({
    required this.id,
    required this.ticketId,
    required this.changedBy,
    this.oldStatus,
    required this.newStatus,
    required this.createdAt,
  });

  String get action {
    if (oldStatus == null) return 'Created';
    return 'Status Updated';
  }

  String get description {
    if (oldStatus == null) return 'Ticket created with status $newStatus';
    return 'Status changed from $oldStatus to $newStatus';
  }

  String get updatedBy => changedBy;
  DateTime get timestamp => createdAt;
}