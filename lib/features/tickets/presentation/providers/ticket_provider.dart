import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/ticket_enum.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../data/datasources/ticket_local_data_source.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// 2. Provider untuk Local Data Source
final ticketLocalDataSourceProvider = Provider<TicketLocalDataSource>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return TicketLocalDataSourceImpl(sharedPreferences: sharedPrefs);
});

// 3. Provider untuk Remote Data Source
final ticketRemoteDataSourceProvider = Provider<TicketRemoteDataSource>((ref) {
  return TicketRemoteDataSourceImpl(client: http.Client());
});

// 4. Provider untuk Repository (menggunakan remote + local + sharedPrefs)
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final localDataSource = ref.watch(ticketLocalDataSourceProvider);
  final remoteDataSource = ref.watch(ticketRemoteDataSourceProvider);
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  
  return TicketRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    sharedPreferences: sharedPrefs,
  );
});

// 5. Notifier untuk List Tiket
class TicketListNotifier extends AsyncNotifier<List<TicketEntity>> {
  @override
  Future<List<TicketEntity>> build() async {
    final tickets = await ref.read(ticketRepositoryProvider).getTickets();
    return tickets;
  }

  Future<void> refresh() async {
    state = const AsyncLoading(); // Set status ke loading saat refresh
    state = await AsyncValue.guard(() {
      return ref.read(ticketRepositoryProvider).getTickets();
    });
  }

  Future<void> addTicket(TicketEntity ticket) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. Create ticket first
      final createdTicket = await ref.read(ticketRepositoryProvider).createTicket(ticket);

      // 2. If online and has attachments, upload each file
      if (ticket.attachments.isNotEmpty && createdTicket != null) {
        final repo = ref.read(ticketRepositoryProvider);
        if (repo is TicketRepositoryImpl && repo.isOnline) {
          final remote = ref.read(ticketRemoteDataSourceProvider);
          final token = repo.token!;

          // Upload each attachment
          for (final path in ticket.attachments) {
            final file = File(path);
            if (await file.exists()) {
              try {
                final bytes = await file.readAsBytes();
                final filename = path.split('/').last;
                await remote.uploadAttachment(token, createdTicket.id, bytes, filename);
              } catch (e) {
                // Continue if one attachment fails
                print('Failed to upload attachment: $e');
              }
            }
          }
        }
      }

      return ref.read(ticketRepositoryProvider).getTickets();
    });
  }

  Future<void> sendComment({
    required String ticketId,
    required CommentEntity comment,
    String? parentCommentId,
  }) async {
    try {
      await ref
          .read(ticketRepositoryProvider)
          .addComment(ticketId, comment, parentCommentId: parentCommentId);

      // Ambil comments terbaru
      final comments = await ref.read(ticketRepositoryProvider).getComments(ticketId);

      // Update ticket di list dengan comments baru
      final currentTickets = state.whenOrNull(data: (data) => data) ?? [];
      final updatedTickets = currentTickets.map((t) {
        if (t.id == ticketId) {
          return TicketModel(
            id: t.id,
            title: t.title,
            description: t.description,
            status: t.status,
            priority: t.priority,
            createdAt: t.createdAt,
            userId: t.userId,
            attachments: t.attachments,
            comments: comments,
          );
        }
        return t;
      }).toList();

      state = AsyncValue.data(updatedTickets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus(String ticketId, TicketStatus newStatus) async {
    try {
      final user = ref.read(currentUserProvider);
      await ref.read(ticketRepositoryProvider).updateTicketStatus(
        ticketId, 
        newStatus, 
        user?.name ?? "Admin"
      );

      // Ambil data terbaru
      final updatedTickets = await ref.read(ticketRepositoryProvider).getTickets();
      state = AsyncValue.data(updatedTickets);

      // Tampilkan notifikasi
      await NotificationService.showNotification(
        id: ticketId.hashCode,
        title: "Update Tiket #${ticketId.toUpperCase()}",
        body: "Status tiket Anda kini: ${newStatus.label}",
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final ticketListProvider =
    AsyncNotifierProvider<TicketListNotifier, List<TicketEntity>>(() {
      return TicketListNotifier();
    });

final ticketStatsProvider = Provider<Map<String, int>>((ref) {
  final ticketsAsync = ref.watch(ticketListProvider);

  return ticketsAsync.maybeWhen(
    data: (tickets) {
      return {
        'total': tickets.length,
        'open': tickets.where((t) => t.status == TicketStatus.open).length,
        'inProgress': tickets
            .where((t) => t.status == TicketStatus.inProgress)
            .length,
        'resolved': tickets
            .where((t) => t.status == TicketStatus.resolved)
            .length,
        'closed': tickets.where((t) => t.status == TicketStatus.closed).length,
      };
    },
    orElse: () => {
      'total': 0,
      'open': 0,
      'inProgress': 0,
      'resolved': 0,
      'closed': 0,
    },
  );
});