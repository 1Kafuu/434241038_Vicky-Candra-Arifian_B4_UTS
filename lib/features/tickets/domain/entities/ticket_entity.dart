import 'ticket_enum.dart';
import 'comment_entity.dart';
import 'ticket_history_entity.dart';

class TicketEntity {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime createdAt;
  final String userId;
  final String? assignedTo;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<String> attachments;
  final List<CommentEntity> comments;
  final List<TicketHistoryEntity> history;

  const TicketEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.userId,
    this.assignedTo,
    this.updatedAt,
    this.resolvedAt,
    this.attachments = const [],
    this.comments = const [],
    this.history = const []
  });
}