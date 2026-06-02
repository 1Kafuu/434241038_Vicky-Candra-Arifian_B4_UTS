import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Tambahkan Riverpod
import '../../../../core/theme/app_colors.dart';
import '../providers/ticket_provider.dart'; // Tambahkan provider
import '../../domain/entities/ticket_history_entity.dart';

// Ubah menjadi ConsumerWidget agar bisa akses provider
class GlobalHistoryScreen extends ConsumerWidget {
  const GlobalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ambil semua data tiket untuk mengumpulkan semua history
    final ticketsAsync = ref.watch(ticketListProvider);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        title: Text(
          "Riwayat Aktivitas Global",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        elevation: 0,
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          // 1. Gabungkan semua history dari tiap tiket menjadi satu list
          final List<Map<String, dynamic>> allHistoryEntries = [];
          
          for (var ticket in tickets) {
            for (var h in ticket.history) {
              allHistoryEntries.add({
                'ticketId': ticket.id,
                'data': h,
              });
            }
          }

          // 2. Urutkan berdasarkan waktu terbaru (Global)
          allHistoryEntries.sort((a, b) => 
            (b['data'] as TicketHistoryEntity).createdAt.compareTo(
            (a['data'] as TicketHistoryEntity).createdAt));

          if (allHistoryEntries.isEmpty) {
            return Center(
              child: Text(
                "Belum ada riwayat aktivitas",
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: allHistoryEntries.length,
            itemBuilder: (context, index) {
              final entry = allHistoryEntries[index];
              final item = entry['data'] as TicketHistoryEntity;
              final ticketId = entry['ticketId'] as String;
              final isLast = index == allHistoryEntries.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kolom Timeline
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 4,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Konten History dengan tambahan ID Tiket
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.action,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              // Tambahan Badge ID Tiket agar user tahu ini update tiket mana
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "#$ticketId",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Oleh: ${item.updatedBy} • ${item.timestamp.day}/${item.timestamp.month} ${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            "Error: $err",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}