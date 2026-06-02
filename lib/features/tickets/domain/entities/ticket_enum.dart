enum TicketStatus {
  open('Open'),
  assigned('Assigned'),
  inProgress('In Progress'),
  pending('Pending'),
  resolved('Resolved'),
  closed('Closed');

  final String label;
  const TicketStatus(this.label);
}

enum TicketPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String label;
  const TicketPriority(this.label);
}