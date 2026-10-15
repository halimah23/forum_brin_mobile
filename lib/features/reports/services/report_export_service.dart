import '../../questions/models/question_model.dart';

class ReportExportService {
  /// Escape string agar aman di format CSV (RFC 4180)
  static String _escapeCsv(dynamic val) {
    if (val == null) return '""';
    final str = val.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Menghasilkan format string CSV dari daftar tiket
  static String generateTicketsCsv(List<QuestionModel> tickets) {
    final buffer = StringBuffer();

    // 1. Header CSV
    final headers = [
      'No',
      'No Tiket',
      'Tanggal Masuk',
      'Nama Pegawai',
      'Unit Kerja',
      'Judul Pertanyaan',
      'Kategori / Tugas Fungsi',
      'Kawasan LKSDM',
      'Tim Penangan Pusat',
      'Status Tiket',
      'Durasi Penanganan (Jam)',
      'Status SLA (48 Jam)',
      'Rating CSAT (1-5)',
      'Ulasan Feedback',
    ];

    buffer.writeln(headers.map(_escapeCsv).join(','));

    // 2. Baris Data Tiket
    for (int i = 0; i < tickets.length; i++) {
      final q = tickets[i];
      final noStr = (i + 1).toString();
      final ticketNum = q.ticketNumber ?? '-';
      final tanggalMasuk = q.createdAt != null
          ? q.createdAt!.replaceAll('T', ' ').split('.').first
          : '-';
      final namaPegawai = q.user?.name ?? 'Pegawai';
      final unitKerja = q.user?.unit ?? '-';
      final judul = q.judul;
      final tusi = q.tugasFungsiNama ??
          ((q.tugasFungsi != null && q.tugasFungsi!.isNotEmpty)
              ? q.tugasFungsi!.first.nama
              : '-');
      final lksdm = q.lksdmKawasan ?? '-';
      final targetPusat = q.targetTimPusat ?? q.targetTim ?? '-';
      final statusLabel = q.ticketStatus.label;
      final durasiJam = q.durationWorked.inHours.toString();
      final statusSla = q.isClosed
          ? (q.isSlaBreached ? 'Selesai Terlambat' : 'Selesai Tepat Waktu')
          : (q.isSlaBreached ? 'Melebihi SLA' : 'Berjalan Sesuai SLA');
      final csat = q.rating != null ? '${q.rating} / 5' : 'Belum Dinilai';
      final feedback = q.ratingFeedback ?? '-';

      final row = [
        noStr,
        ticketNum,
        tanggalMasuk,
        namaPegawai,
        unitKerja,
        judul,
        tusi,
        lksdm,
        targetPusat,
        statusLabel,
        durasiJam,
        statusSla,
        csat,
        feedback,
      ];

      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    return buffer.toString();
  }

  /// Statistik agregat untuk ringkasan laporan
  static Map<String, dynamic> calculateSummary(List<QuestionModel> tickets) {
    final total = tickets.length;
    final closed = tickets.where((q) => q.isClosed).length;
    final active = tickets.where((q) => q.isActive).length;

    int onTimeCount = 0;
    int ratedCount = 0;
    int totalRatingScore = 0;

    for (final q in tickets) {
      if (!q.isSlaBreached) {
        onTimeCount++;
      }
      if (q.rating != null && q.rating! > 0) {
        ratedCount++;
        totalRatingScore += q.rating!;
      }
    }

    final double slaRate = total > 0 ? (onTimeCount / total) * 100 : 100.0;
    final double avgCsat =
        ratedCount > 0 ? totalRatingScore / ratedCount : 0.0;

    return {
      'totalTickets': total,
      'closedTickets': closed,
      'activeTickets': active,
      'slaComplianceRate': slaRate,
      'averageCsat': avgCsat,
      'totalRatings': ratedCount,
    };
  }
}
