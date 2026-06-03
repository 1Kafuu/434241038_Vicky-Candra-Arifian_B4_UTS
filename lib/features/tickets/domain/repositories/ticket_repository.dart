import 'package:e_ticketing/features/tickets/domain/entities/ticket_enum.dart';

import '../entities/ticket_entity.dart';
import '../entities/comment_entity.dart';
import '../entities/ticket_history_entity.dart';

abstract class TicketRepository {
  /// Mengambil semua daftar tiket
  Future<List<TicketEntity>> getTickets();

  /// Ambil satu tiket berdasarkan ID (online only)
  Future<TicketEntity?> getTicketById(String ticketId);

  /// Membuat tiket baru
  Future<TicketEntity?> createTicket(TicketEntity ticket);

  /// Memperbarui data tiket yang sudah ada
  Future<void> updateTicket(TicketEntity ticket);

  Future<void> addComment(String ticketId, CommentEntity comment, {String? parentCommentId});

  /// Ambil comments untuk satu ticket
  Future<List<CommentEntity>> getComments(String ticketId);

  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus, String adminName);

  /// Hapus komentar pada tiket
  Future<void> deleteComment({
    required String token,
    required String ticketId,
    required String commentId,
  });

  /// Resolve/close ticket (Admin only)
  Future<void> resolveTicket(String ticketId);

  /// Menutup tiket setelah Resolved (Admin only)
  Future<void> closeTicket(String ticketId);

  /// Assign support/helpdesk to ticket (Admin only)
  Future<void> assignTicket(String ticketId, String assignedTo);

  /// Ambil semua history tiket (filtered by role di backend)
  Future<List<TicketHistoryEntity>> getAllHistory();
}