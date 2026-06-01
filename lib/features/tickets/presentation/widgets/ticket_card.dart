import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/ticket_enum.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';

class TicketCard extends StatelessWidget {
  final TicketEntity ticket;
  final bool isDark;
  const TicketCard({super.key, required this.ticket, this.isDark = false});

  // Helper to resolve any stored attachment string to a full URL
  String _resolveAttachmentUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    final clean = path.startsWith('/') ? path.substring(1) : path;
    if (clean.startsWith('uploads/')) {
      return '$base/$clean';
    }
    return '$base/uploads/attachments/$clean';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        // 1. Ganti Row jadi Column
        crossAxisAlignment:
            CrossAxisAlignment.start, // 2. Ratakan konten ke kiri
        children: [
          if (ticket.attachments.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _resolveAttachmentUrl(ticket.attachments.first),
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image_outlined, 
                color: isDark ? Colors.grey.shade400 : AppColors.primary,
              ),
            ),

          const SizedBox(height: 12), // Beri jarak antara gambar dan teks
          // Info Tiket
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // Gunakan Row di sini agar judul dan badge status tetap sejajar menyamping
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.status.label,
                      style: TextStyle(
                        color: _getStatusColor(ticket.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ticket.description,
                maxLines: 2, // Deskripsi bisa lebih panjang dikit
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    // Logika warna berdasarkan TicketStatus enum
    switch (status) {
      case TicketStatus.open:
        return Colors.green;
      case TicketStatus.pending:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.purple;
      case TicketStatus.closed:
        return Colors.grey;
      case TicketStatus.inProgress:
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}
