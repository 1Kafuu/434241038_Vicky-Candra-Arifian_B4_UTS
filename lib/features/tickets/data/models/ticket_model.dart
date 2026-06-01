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
        (e) => e.label == json['priority'], // Cek berdasarkan label
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.label == json['status'], // Cek berdasarkan label
        orElse: () => TicketStatus.open,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
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
      'status': status.label, // Simpan labelnya saja: "Open"
      'priority': priority.label, // Simpan labelnya saja: "Low"
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
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
            timestamp: DateTime.tryParse(c['timestamp'] ?? c['createdAt'] ?? '') ?? DateTime.now(),
            replies: _commentsFromJson(c['replies']), // Rekursif untuk balasan
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
            'timestamp': c.timestamp.toIso8601String(),
            'replies': _commentsToJson(c.replies), // Rekursif untuk balasan
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
        action: item['action'],
        description: item['description'],
        timestamp: DateTime.parse(item['timestamp']),
        updatedBy: item['updatedBy'],
      );
    }).toList();
  }

  static List<Map<String, dynamic>> _historyToJson(
    List<TicketHistoryEntity> historyList,
  ) {
    return historyList.map((item) {
      return {
        'id': item.id,
        'action': item.action,
        'description': item.description,
        'timestamp': item.timestamp.toIso8601String(),
        'updatedBy': item.updatedBy,
      };
    }).toList();
  }
}
