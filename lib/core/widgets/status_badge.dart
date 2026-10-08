import 'package:flutter/material.dart';
import '../constants/app_radius.dart';
import '../constants/app_typography.dart';
import '../../features/questions/models/ticket_status.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final ticketStatus = TicketStatus.fromString(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ticketStatus.color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: ticketStatus.color.withAlpha(80), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ticketStatus.icon, size: 12, color: ticketStatus.color),
          const SizedBox(width: 4),
          Text(
            ticketStatus.label,
            style: AppTypography.caption.copyWith(
              color: ticketStatus.color,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
