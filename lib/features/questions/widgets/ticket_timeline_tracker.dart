import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../models/question_model.dart';

class TicketTimelineTracker extends StatefulWidget {
  final QuestionModel question;

  const TicketTimelineTracker({
    super.key,
    required this.question,
  });

  @override
  State<TicketTimelineTracker> createState() => _TicketTimelineTrackerState();
}

class _TicketTimelineTrackerState extends State<TicketTimelineTracker> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isClosed = q.isClosed;
    final isEscalated = q.isEscalated;
    final isHandledLksdm = q.status == 'ditangani_lksdm' || isEscalated || isClosed;

    // SLA Calculation
    final isBreached = q.isSlaBreached;
    final remaining = q.remainingSlaDuration;

    final Color slaBadgeColor;
    final Color slaTextColor;
    final String slaText;
    final IconData slaIcon;

    if (isClosed) {
      if (isBreached) {
        slaBadgeColor = const Color(0xFFFEF3C7);
        slaTextColor = const Color(0xFFB45309);
        slaText = 'Selesai (${q.durationWorked.inHours}j - Lewat SLA)';
        slaIcon = Icons.warning_amber_rounded;
      } else {
        slaBadgeColor = const Color(0xFFDCFCE7);
        slaTextColor = const Color(0xFF15803D);
        slaText = 'Selesai Tepat Waktu (${q.durationWorked.inHours}j)';
        slaIcon = Icons.check_circle_rounded;
      }
    } else {
      if (isBreached) {
        slaBadgeColor = const Color(0xFFFEE2E2);
        slaTextColor = const Color(0xFFB91C1C);
        slaText = 'Melebihi SLA 48 Jam (${q.durationWorked.inHours}j)';
        slaIcon = Icons.alarm_off_rounded;
      } else if (remaining.inHours <= 12) {
        slaBadgeColor = const Color(0xFFFEF3C7);
        slaTextColor = const Color(0xFFB45309);
        slaText = 'SLA Kritis (Sisa ${remaining.inHours}j)';
        slaIcon = Icons.hourglass_bottom_rounded;
      } else {
        slaBadgeColor = const Color(0xFFDCFCE7);
        slaTextColor = const Color(0xFF15803D);
        slaText = 'SLA Aman (Sisa ${remaining.inHours}j)';
        slaIcon = Icons.access_time_rounded;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.route_outlined, size: 20, color: AppColors.primaryRed),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Perjalanan Tiket & SLA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: slaBadgeColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(slaIcon, size: 13, color: slaTextColor),
                        const SizedBox(width: 4),
                        Text(
                          slaText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: slaTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.slate400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTimelineStep(
                    stepNumber: 1,
                    title: 'Tiket Diajukan',
                    subtitle: 'Tiket berhasil masuk ke sistem BOSDM Connect',
                    time: q.createdAt?.replaceAll('T', ' ').split('.').first,
                    actor: q.user?.name ?? 'Pegawai',
                    isCompleted: true,
                    isActive: q.status == 'menunggu_lksdm',
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    stepNumber: 2,
                    title: 'Verifikasi Kawasan LKSDM',
                    subtitle: q.lksdmKawasan != null
                        ? 'Ditinjau oleh ${q.lksdmKawasan}'
                        : 'Ditinjau oleh staf layanan kawasan',
                    actor: q.assignedTo ?? 'Staf Admin LKSDM',
                    isCompleted: isHandledLksdm,
                    isActive: q.status == 'ditangani_lksdm',
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    stepNumber: 3,
                    title: 'Penanganan Tim Pusat / Ahli',
                    subtitle: q.targetTimPusat != null
                        ? 'Disposisi ke ${q.targetTimPusat}'
                        : (q.targetTim != null ? 'Penanganan oleh ${q.targetTim}' : 'Penanganan tim teknis'),
                    actor: q.targetTimPusat ?? q.targetTim ?? 'Tim Teknis BOSDM',
                    isCompleted: isClosed || isEscalated,
                    isActive: isEscalated && !isClosed,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    stepNumber: 4,
                    title: 'Tiket Selesai',
                    subtitle: isClosed
                        ? 'Solusi telah diberikan dan tiket ditutup'
                        : 'Menunggu konfirmasi penyelesaian',
                    time: q.resolvedAt?.replaceAll('T', ' ').split('.').first,
                    isCompleted: isClosed,
                    isActive: isClosed,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    String? time,
    String? actor,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final Color stepColor = isCompleted
        ? const Color(0xFF16A34A)
        : (isActive ? AppColors.primaryRed : AppColors.slate300);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Icon & Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF16A34A)
                      : (isActive ? AppColors.primaryRed : Colors.white),
                  border: Border.all(
                    color: stepColor,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Center(
                        child: Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppColors.slate400,
                          ),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFF16A34A) : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Step Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCompleted || isActive
                                ? AppColors.slate900
                                : AppColors.slate400,
                          ),
                        ),
                      ),
                      if (time != null)
                        Text(
                          time,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.slate500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCompleted || isActive
                          ? AppColors.slate600
                          : AppColors.slate400,
                    ),
                  ),
                  if (actor != null && (isCompleted || isActive)) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pihak: $actor',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
