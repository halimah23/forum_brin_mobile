import 'package:flutter/material.dart';
import '../constants/app_radius.dart';
import '../constants/app_typography.dart';
import '../utils/operational_hours_helper.dart';
import '../../features/questions/models/ticket_status.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool useShortLabel;
  final TicketStatus? ticketStatusOverride;

  const StatusBadge({
    super.key,
    required this.status,
    this.useShortLabel = false,
    this.ticketStatusOverride,
  });

  @override
  Widget build(BuildContext context) {
    TicketStatus ticketStatus = ticketStatusOverride ?? TicketStatus.fromString(status);

    // Auto-resolve jika tiket luar jam kerja sudah memasuki jam operasional resmi
    if (ticketStatus == TicketStatus.offHoursQueue && OperationalHoursHelper.isWithinWorkingHours()) {
      ticketStatus = TicketStatus.open;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ticketStatus.color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: ticketStatus.color.withAlpha(80), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ticketStatus.icon, size: 11, color: ticketStatus.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              useShortLabel ? ticketStatus.shortLabel : ticketStatus.label,
              style: AppTypography.caption.copyWith(
                color: ticketStatus.color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
