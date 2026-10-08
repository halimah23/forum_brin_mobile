import 'package:flutter/material.dart';

enum TicketStatus {
  open('OPEN', 'Open (Antrean LKSDM)', Color(0xFFD97706), Icons.hourglass_top_rounded),
  inProgress('IN_PROGRESS', 'Ditangani LKSDM', Color(0xFF0D9488), Icons.support_agent_rounded),
  waitingUser('WAITING_USER', 'Menunggu Konfirmasi Pegawai', Color(0xFF0284C7), Icons.mark_chat_unread_outlined),
  escalated('ESCALATED', 'Dialihkan ke Pusat', Color(0xFFC2410C), Icons.alt_route_rounded),
  inProgressCenter('IN_PROGRESS_CENTER', 'Ditangani Staf Pusat', Color(0xFF7C3AED), Icons.engineering_outlined),
  resolved('RESOLVED', 'Solusi Diberikan', Color(0xFF16A34A), Icons.task_alt_rounded),
  closed('CLOSED', 'Selesai (Closed)', Color(0xFF475569), Icons.check_circle_outline_rounded);

  final String dbKey;
  final String label;
  final Color color;
  final IconData icon;

  const TicketStatus(this.dbKey, this.label, this.color, this.icon);

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
