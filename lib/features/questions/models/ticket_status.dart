import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum TicketStatus {
  open('OPEN', 'Belum Ditangani', AppColors.colorAccentWarm, Icons.hourglass_top_rounded),
  inProgress('IN_PROGRESS', 'Sedang Ditangani', AppColors.colorSecondary, Icons.support_agent_rounded),
  waitingUser('WAITING_USER', 'Menunggu Konfirmasi', AppColors.colorPrimary, Icons.mark_chat_unread_outlined),
  escalated('ESCALATED', 'Eskalasi Pusat', AppColors.colorAccentWarm, Icons.alt_route_rounded),
  inProgressCenter('IN_PROGRESS_CENTER', 'Ditangani Staf Pusat', AppColors.colorSecondaryStrong, Icons.engineering_outlined),
  mandiriLksdm('TIKET_MANDIRI_LKSDM', 'Konsultasi LKSDM ke Pusat', AppColors.colorPrimaryHover, Icons.badge_outlined),
  offHoursQueue('ANTREAN_LUAR_JAM_KERJA', 'Antrean Luar Jam Kerja', Color(0xFF64748B), Icons.nightlight_round),
  resolved('RESOLVED', 'Selesai', AppColors.success, Icons.task_alt_rounded),
  closed('CLOSED', 'Selesai', AppColors.colorTextMuted, Icons.check_circle_outline_rounded),
  cancelled('DIBATALKAN', 'Dibatalkan', Color(0xFFEF4444), Icons.cancel_outlined);

  final String dbKey;
  final String label;
  final Color color;
  final IconData icon;

  const TicketStatus(this.dbKey, this.label, this.color, this.icon);

  /// Label ringkas responsif untuk badge pada layar ponsel berbagai ukuran
  String get shortLabel {
    switch (this) {
      case TicketStatus.open:
        return 'Belum Ditangani';
      case TicketStatus.inProgress:
        return 'Sedang Ditangani';
      case TicketStatus.waitingUser:
        return 'Menunggu Konfirmasi';
      case TicketStatus.escalated:
        return 'Eskalasi Pusat';
      case TicketStatus.inProgressCenter:
        return 'Ditangani Pusat';
      case TicketStatus.mandiriLksdm:
        return 'Konsultasi LKSDM';
      case TicketStatus.offHoursQueue:
        return 'Luar Jam Kerja';
      case TicketStatus.resolved:
      case TicketStatus.closed:
        return 'Selesai';
      case TicketStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  /// Parse dari string status database (kompatibel 100% data lama & baru PRD)
  static TicketStatus fromString(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) return TicketStatus.open;
    final normalized = rawStatus.toUpperCase().trim();

    switch (normalized) {
      case 'OPEN':
      case 'MENUNGGU_LKSDM':
      case 'MENUNGGU_DISPOSISI':
      case 'MENUNGGU_APPROVAL':
      case 'PENDING':
      case 'DIAJUKAN':
        return TicketStatus.open;

      case 'IN_PROGRESS':
      case 'DITANGANI_LKSDM':
      case 'SEDANG_DIPROSES':
      case 'DIPROSES':
        return TicketStatus.inProgress;

      case 'WAITING_USER':
      case 'MENUNGGU_KONFIRMASI_PEGAWAI':
        return TicketStatus.waitingUser;

      case 'ESCALATED':
      case 'DIALIHKAN_KE_PUSAT':
      case 'ESKALASI_PUSAT':
        return TicketStatus.escalated;

      case 'IN_PROGRESS_CENTER':
      case 'DITANGANI_PUSAT':
        return TicketStatus.inProgressCenter;

      case 'TIKET_MANDIRI_LKSDM':
      case 'KONSULTASI_LKSDM':
      case 'MANDIRI_LKSDM':
        return TicketStatus.mandiriLksdm;

      case 'ANTREAN_LUAR_JAM_KERJA':
      case 'LUAR_JAM_KERJA':
      case 'OFF_HOURS':
        return TicketStatus.offHoursQueue;

      case 'RESOLVED':
      case 'DIJAWAB':
        return TicketStatus.resolved;

      case 'CLOSED':
      case 'SELESAI':
        return TicketStatus.closed;

      case 'DIBATALKAN':
      case 'CANCELLED':
      case 'DELETED':
        return TicketStatus.cancelled;

      default:
        return TicketStatus.open;
    }
  }

  bool get isClosed => this == TicketStatus.closed || this == TicketStatus.cancelled;
  bool get isActive => this != TicketStatus.closed && this != TicketStatus.cancelled;
}
