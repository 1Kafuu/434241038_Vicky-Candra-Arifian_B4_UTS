import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/ticket_enum.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/ticket_history_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_local_data_source.dart';
import '../datasources/ticket_remote_datasource.dart';
import '../models/ticket_model.dart';

const String _tokenKey = 'auth_token';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource? remoteDataSource;
  final TicketLocalDataSource? localDataSource;
  final SharedPreferences sharedPreferences;

  TicketRepositoryImpl({
    this.remoteDataSource,
    this.localDataSource,
    required this.sharedPreferences,
  });

  String? get token => sharedPreferences.getString(_tokenKey);

  bool get isOnline => token != null && remoteDataSource != null;

  @override
  Future<List<TicketEntity>> getTickets() async {
    if (isOnline) {
      final tickets = await remoteDataSource!.getTickets(token!);
      return tickets;
    }
    // Fallback to local
    final ticketMaps = await localDataSource!.getTickets();
    return ticketMaps.map((map) => TicketModel.fromJson(map)).toList();
  }

  @override
  Future<TicketEntity?> createTicket(TicketEntity ticket) async {
    if (isOnline) {
      final created = await remoteDataSource!.createTicket(
        token!,
        title: ticket.title,
        description: ticket.description,
        priority: ticket.priority,
      );
      return created;
    }
    // Fallback to local
    final model = TicketModel(
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: ticket.status,
      priority: ticket.priority,
      createdAt: ticket.createdAt,
      userId: ticket.userId,
      assignedTo: ticket.assignedTo,
      updatedAt: ticket.updatedAt,
      resolvedAt: ticket.resolvedAt,
      attachments: ticket.attachments,
      comments: ticket.comments,
    );
    await localDataSource!.addTicket(model.toJson());
  }

  @override
  Future<void> updateTicket(TicketEntity ticket) async {
    if (isOnline) {
      return;
    }
    // Fallback to local
    final model = TicketModel(
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: ticket.status,
      priority: ticket.priority,
      createdAt: ticket.createdAt,
      userId: ticket.userId,
      assignedTo: ticket.assignedTo,
      updatedAt: ticket.updatedAt,
      resolvedAt: ticket.resolvedAt,
      attachments: ticket.attachments,
      comments: ticket.comments,
    );
    await localDataSource!.updateTicket(model.toJson());
  }

  @override
  Future<void> updateTicketStatus(
    String ticketId,
    TicketStatus newStatus,
    String adminName,
  ) async {
    if (isOnline) {
      await remoteDataSource!.updateTicketStatus(
        token!,
        ticketId,
        newStatus.label,
      );
      return;
    }
    // Fallback to local
    final tickets = await getTickets();
    final index = tickets.indexWhere((t) => t.id == ticketId);

    if (index != -1) {
      final ticket = tickets[index];
      final newHistoryEntry = TicketHistoryEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ticketId: ticketId,
        changedBy: adminName,
        oldStatus: ticket.status.label,
        newStatus: newStatus.label,
        createdAt: DateTime.now(),
      );

      final updatedTicket = TicketModel(
        id: ticket.id,
        title: ticket.title,
        description: ticket.description,
        status: newStatus,
        priority: ticket.priority,
        createdAt: ticket.createdAt,
        userId: ticket.userId,
        assignedTo: ticket.assignedTo,
        updatedAt: DateTime.now(),
        resolvedAt: ticket.resolvedAt,
        attachments: ticket.attachments,
        comments: ticket.comments,
        history: [...ticket.history, newHistoryEntry],
      );

      await localDataSource!.updateTicket(updatedTicket.toJson());
    }
  }

  @override
  Future<void> addComment(
    String ticketId,
    CommentEntity comment, {
    String? parentCommentId,
  }) async {
    if (isOnline) {
      await remoteDataSource!.addComment(
        token!,
        ticketId,
        comment.message,
        parentCommentId: parentCommentId,
      );
      return;
    }
    // Fallback to local
    final tickets = await getTickets();
    final index = tickets.indexWhere((t) => t.id == ticketId);

    if (index != -1) {
      final ticket = tickets[index];
      List<CommentEntity> updatedComments = List.from(ticket.comments);

      if (parentCommentId == null) {
        updatedComments.add(comment);
      } else {
        final parentIndex = updatedComments.indexWhere(
          (c) => c.id == parentCommentId,
        );
        if (parentIndex != -1) {
          final parent = updatedComments[parentIndex];
          final updatedReplies = List<CommentEntity>.from(parent.replies)
            ..add(comment);

          updatedComments[parentIndex] = CommentEntity(
            id: parent.id,
            senderName: parent.senderName,
            senderId: parent.senderId,
            message: parent.message,
            timestamp: parent.timestamp,
            replies: updatedReplies,
          );
        }
      }

      final updatedTicket = TicketModel(
        id: ticket.id,
        title: ticket.title,
        description: ticket.description,
        status: ticket.status,
        priority: ticket.priority,
        createdAt: ticket.createdAt,
        userId: ticket.userId,
        assignedTo: ticket.assignedTo,
        updatedAt: ticket.updatedAt,
        resolvedAt: ticket.resolvedAt,
        attachments: ticket.attachments,
        comments: updatedComments,
      );

      await localDataSource!.updateTicket(updatedTicket.toJson());
    }
  }

  @override
  Future<List<CommentEntity>> getComments(String ticketId) async {
    if (isOnline) {
      final response = await remoteDataSource!.getComments(token!, ticketId);
      return _parseComments(response);
    }
    // Fallback local: not implemented
    return [];
  }

  List<CommentEntity> _parseComments(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((c) => CommentEntity(
      id: c['id'] ?? '',
      senderName: c['senderName'] ?? 'Unknown',
      senderId: c['senderId'] ?? '',
      message: c['message'] ?? '',
      timestamp: DateTime.tryParse(c['createdAt'] ?? c['timestamp'] ?? '') ?? DateTime.now(),
      parentCommentId: c['parentCommentId'],
    )).toList();
  }

  @override
  Future<void> deleteComment({
    required String token,
    required String ticketId,
    required String commentId,
  }) async {
    if (isOnline) {
      await remoteDataSource!.deleteComment(token, ticketId, commentId);
      return;
    }
    // Fallback to local: hapus dari list comment di ticket
    final tickets = await getTickets();
    final index = tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;

    final ticket = tickets[index];
    final updatedComments = ticket.comments
        .where((c) => c.id != commentId)
        .map((c) {
      // Hapus juga reply yang parent-nya adalah comment yang dihapus
      final remainingReplies = c.replies.where((r) => r.id != commentId).toList();
      return CommentEntity(
        id: c.id,
        senderName: c.senderName,
        senderId: c.senderId,
        message: c.message,
        timestamp: c.timestamp,
        parentCommentId: c.parentCommentId,
        replies: remainingReplies,
      );
    }).toList();

    final updatedTicket = TicketModel(
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: ticket.status,
      priority: ticket.priority,
      createdAt: ticket.createdAt,
      userId: ticket.userId,
      assignedTo: ticket.assignedTo,
      updatedAt: DateTime.now(),
      resolvedAt: ticket.resolvedAt,
      attachments: ticket.attachments,
      comments: updatedComments,
    );
    await localDataSource!.updateTicket(updatedTicket.toJson());
  }

  @override
  Future<void> resolveTicket(String ticketId) async {
    if (isOnline) {
      await remoteDataSource!.resolveTicket(token!, ticketId);
    }
  }

  @override
  Future<void> assignTicket(String ticketId, String assignedTo) async {
    if (isOnline) {
      await remoteDataSource!.assignTicket(token!, ticketId, assignedTo);
    }
  }
}