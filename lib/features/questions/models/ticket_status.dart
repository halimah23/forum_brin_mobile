import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum TicketStatus {
  open('OPEN', 'Open (Antrean LKSDM)', AppColors.colorAccentWarm, Icons.hourglass_top_rounded),
  inProgress('IN_PROGRESS', 'Ditangani LKSDM', AppColors.colorSecondary, Icons.support_agent_rounded),
  waitingUser('WAITING_USER', 'Menunggu Konfirmasi Pegawai', AppColors.colorPrimary, Icons.mark_chat_unread_outlined),
  escalated('ESCALATED', 'Dialihkan ke Pusat', AppColors.colorAccentWarm, Icons.alt_route_rounded),
  inProgressCenter('IN_PROGRESS_CENTER', 'Ditangani Staf Pusat', AppColors.colorSecondaryStrong, Icons.engineering_outlined),
  mandiriLksdm('TIKET_MANDIRI_LKSDM', 'Konsultasi LKSDM ke Pusat', AppColors.colorPrimaryHover, Icons.badge_outlined),
  resolved('RESOLVED', 'Solusi Diberikan', AppColors.success, Icons.task_alt_rounded),
  closed('CLOSED', 'Selesai (Closed)', AppColors.colorTextMuted, Icons.check_circle_outline_rounded);

  final String dbKey;
  final String label;
  final Color color;
  final IconData icon;

  const TicketStatus(this.dbKey, this.label, this.color, this.icon);

  /// Label ringkas responsif untuk badge pada layar ponsel berbagai ukuran
  String get shortLabel {
    switch (this) {
      case TicketStatus.open:
        return 'Antrean LKSDM';
      case TicketStatus.inProgress:
        return 'Ditangani LKSDM';
      case TicketStatus.waitingUser:
        return 'Konfirmasi Pegawai';
      case TicketStatus.escalated:
        return 'Dialihkan ke Pusat';
      case TicketStatus.inProgressCenter:
        return 'Ditangani Pusat';
      case TicketStatus.mandiriLksdm:
        return 'Konsultasi LKSDM';
      case TicketStatus.resolved:
        return 'Solusi Diberikan';
      case TicketStatus.closed:
        return 'Selesai';
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

      case 'RESOLVED':
      case 'DIJAWAB':
        return TicketStatus.resolved;

      case 'CLOSED':
      case 'SELESAI':
        return TicketStatus.closed;

      default:
        return TicketStatus.open;
    }
  }

  bool get isClosed => this == TicketStatus.closed;
  bool get isActive => this != TicketStatus.closed;
}
