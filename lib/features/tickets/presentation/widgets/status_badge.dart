import 'package:flutter/material.dart';
import '../../domain/entities/ticket_enum.dart';

class StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;

    // Logika penentuan warna berdasarkan enum status
    switch (status) {
      case TicketStatus.open:
        backgroundColor = Colors.blue.shade600;
        break;
      case TicketStatus.assigned:
        backgroundColor = Colors.indigo.shade600;
        break;
      case TicketStatus.pending:
        backgroundColor = Colors.orange.shade900;
        break;
      case TicketStatus.inProgress:
        backgroundColor = Colors.orange.shade600;
        break;
      case TicketStatus.resolved:
        backgroundColor = Colors.green.shade600;
        break;
      case TicketStatus.closed:
        backgroundColor = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}