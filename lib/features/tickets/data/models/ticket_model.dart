import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/ticket_enum.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/ticket_history_entity.dart';

class TicketModel extends TicketEntity {
  const TicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.createdAt,
    required super.userId,
    super.assignedTo,
    super.updatedAt,
    super.resolvedAt,
    super.attachments,
    super.comments,
    super.history,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: TicketPriority.values.firstWhere(
        (e) => e.label == json['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.label == json['status'],
        orElse: () => TicketStatus.open,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
      assignedTo: json['assignedTo'],
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      attachments: _processAttachments(json['attachments'] ?? []),
      comments: _commentsFromJson(json['comments'] ?? []),
      history: _historyFromJson(json['history']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.label,
      'priority': priority.label,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'assignedTo': assignedTo,
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'attachments': attachments,
      'comments': _commentsToJson(comments),
      'history': _historyToJson(history),
    };
  }

  static List<CommentEntity> _commentsFromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map(
          (c) => CommentEntity(
            id: c['id'],
            senderName: c['senderName'] ?? 'Unknown',
            senderId: c['senderId'] ?? '',
            message: c['message'] ?? '',
            timestamp: DateTime.tryParse(c['createdAt'] ?? c['timestamp'] ?? '') ?? DateTime.now(),
            parentCommentId: c['parentCommentId'],
          ),
        )
        .toList();
  }

  static List<Map<String, dynamic>> _commentsToJson(
    List<CommentEntity> comments,
  ) {
    return comments
        .map(
          (c) => {
            'id': c.id,
            'senderName': c.senderName,
            'senderId': c.senderId,
            'message': c.message,
            'createdAt': c.timestamp.toIso8601String(),
            'parentCommentId': c.parentCommentId,
          },
        )
        .toList();
  }

  static List<String> _processAttachments(dynamic attachments) {
    if (attachments == null) return [];
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    return (attachments as List).map((path) {
      final str = path.toString();
      // Kalau sudah URL lengkap, return langsung
      if (str.startsWith('http')) return str;
      // Kalau sudah ada uploads/attachments, gabung langsung
      if (str.startsWith('uploads/')) return '$baseUrl/$str';
      // Kalau filename aja, tambahkan path uploads/attachments
      return '$baseUrl/uploads/attachments/$str';
    }).toList();
  }

  static List<TicketHistoryEntity> _historyFromJson(dynamic json) {
    if (json == null) return [];
    return (json as List).map((item) {
      return TicketHistoryEntity(
        id: item['id'],
        ticketId: item['ticketId'] ?? '',
        changedBy: item['changedBy'] ?? '',
        oldStatus: item['oldStatus'],
        newStatus: item['newStatus'] ?? '',
        createdAt: DateTime.parse(item['createdAt']),
      );
    }).toList();
  }

  static List<Map<String, dynamic>> _historyToJson(
    List<TicketHistoryEntity> historyList,
  ) {
    return historyList.map((item) {
      return {
        'id': item.id,
        'ticketId': item.ticketId,
        'changedBy': item.changedBy,
        'oldStatus': item.oldStatus,
        'newStatus': item.newStatus,
        'createdAt': item.createdAt.toIso8601String(),
      };
    }).toList();
  }
}
