import 'package:flutter/material.dart';
import '../../domain/entities/ticket_enum.dart';
import '../../../../core/theme/app_colors.dart';

class TicketTrackingStepper extends StatelessWidget {
  final TicketStatus currentStatus;

  const TicketTrackingStepper({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    // Definisi langkah-langkah tracking
    final steps = [
      {'status': TicketStatus.open, 'label': 'Open', 'desc': 'Tiket berhasil dibuat'},
      {'status': TicketStatus.assigned, 'label': 'Assigned', 'desc': 'Ditugaskan ke helpdesk'},
      {'status': TicketStatus.inProgress, 'label': 'In Progress', 'desc': 'Sedang ditangani IT'},
      {'status': TicketStatus.resolved, 'label': 'Resolved', 'desc': 'Solusi telah ditemukan'},
      {'status': TicketStatus.closed, 'label': 'Closed', 'desc': 'Tiket resmi ditutup'},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final stepStatus = steps[index]['status'] as TicketStatus;
        final bool isCompleted = _isCompleted(stepStatus);
        final bool isLast = index == steps.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            children: [
              // Garis dan Lingkaran
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: isCompleted 
                      ? const Icon(Icons.check, size: 12, color: Colors.white) 
                      : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Teks Label dan Deskripsi
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index]['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.textPrimary : Colors.grey,
                        ),
                      ),
                      Text(
                        steps[index]['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  bool _isCompleted(TicketStatus stepStatus) {
    // Urutan logis status tiket
    const statusOrder = [
      TicketStatus.open,
      TicketStatus.assigned,
      TicketStatus.inProgress,
      TicketStatus.resolved,
      TicketStatus.closed,
    ];
    return statusOrder.indexOf(currentStatus) >= statusOrder.indexOf(stepStatus);
  }
}