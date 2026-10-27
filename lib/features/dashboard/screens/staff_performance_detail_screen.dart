import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/export/excel_export_service.dart';
import '../../questions/models/question_model.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../services/performance_analytics_service.dart';

class StaffPerformanceDetailScreen extends StatefulWidget {
  final StaffPerformanceStat staff;
  final List<QuestionModel> allQuestions;
  final int? rank;

  const StaffPerformanceDetailScreen({
    super.key,
    required this.staff,
    required this.allQuestions,
    this.rank,
  });

  @override
  State<StaffPerformanceDetailScreen> createState() =>
      _StaffPerformanceDetailScreenState();
}

class _StaffPerformanceDetailScreenState
    extends State<StaffPerformanceDetailScreen> {
  bool _isDownloading = false;

  List<QuestionModel> get _staffTickets {
    final cleanStaffName = widget.staff.name.trim().toLowerCase();
    return widget.allQuestions.where((q) {
      if (q.id != null && widget.staff.ticketIdsHandled.contains(q.id)) {
        return true;
      }
      final answers = q.answers ?? [];
      return answers.any(
        (a) => a.penjawabNama.trim().toLowerCase() == cleanStaffName,
      );
    }).toList();
  }

  Future<void> _downloadTicketHistory() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final filePath =
          await ExcelExportService.exportStaffTicketHistoryToExcel(
        staff: widget.staff,
        tickets: widget.allQuestions,
      );

      if (!mounted) return;

      final fileName = filePath.split(RegExp(r'[\\/]')).last;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Riwayat berhasil diunduh:\n$fileName',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'BUKA',
            textColor: const Color(0xFF5EEAD4),
            onPressed: () {
              ExcelExportService.openExportedFile(filePath);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh berkas Excel: $e'),
          backgroundColor: AppColors.colorPrimary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _staffTickets;
    final staff = widget.staff;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Kinerja Petugas',
            style: AppTypography.heading3),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Unduh Riwayat Tiket (.xlsx)',
            onPressed: _isDownloading ? null : _downloadTicketHistory,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.colorPrimary,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profil Petugas Header Card
            _buildProfileHeader(staff),

            const SizedBox(height: 16),

            // 2. Grid 4 Kartu KPI
            _buildKpiGrid(staff),

            const SizedBox(height: 16),

            // 3. Distribusi Tag Ulasan Kepuasan
            _buildReviewTagsCard(staff),

            const SizedBox(height: 20),

            // 4. Header Riwayat Tiket + Tombol Download
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Tiket Ditangani (${tickets.length})',
                        style: AppTypography.heading3,
                      ),
                      const Text(
                        'Daftar tiket konsultasi yang direspons oleh petugas ini',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isDownloading ? null : _downloadTicketHistory,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFF0F766E)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export XLSX',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 5. Daftar Kartu Riwayat Tiket
            if (tickets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 36, color: AppColors.slate400),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada tiket yang terhubung secara spesifik.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final q = tickets[index];
                  return _buildTicketHistoryCard(q);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(StaffPerformanceStat staff) {
    final rank = widget.rank;
    Color rankColor = const Color(0xFFD97706);
    if (rank == 2) rankColor = const Color(0xFF64748B);
    if (rank == 3) rankColor = const Color(0xFFB45309);

    final initial =
        staff.name.trim().isNotEmpty ? staff.name.trim()[0].toUpperCase() : 'P';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Petugas
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.colorPrimarySoft,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.colorPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Detail Identitas & Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        staff.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                    if (rank != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: rankColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: rankColor, width: 1),
                        ),
                        child: Text(
                          'Peringkat #$rank',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Badge Peran
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    staff.role,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Unit / Asal Tim
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 13, color: AppColors.slate500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        staff.teamOrLksdm,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.slate600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(StaffPerformanceStat staff) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _buildKpiCard(
          title: 'Tiket Ditangani',
          value: '${staff.ticketsHandledCount}',
          subtitle: 'Tiket konsultasi',
          icon: Icons.confirmation_number_outlined,
          color: const Color(0xFF0284C7),
          bg: const Color(0xFFF0F9FF),
        ),
        _buildKpiCard(
          title: 'Rating Rata-rata',
          value: '${staff.averageRating.toStringAsFixed(1)} ★',
          subtitle: 'Dari ${staff.ratingCount} ulasan',
          icon: Icons.star_rate_rounded,
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFFFBEB),
        ),
        _buildKpiCard(
          title: 'Respon Cepat (Gercep)',
          value: '${staff.gercepCount}',
          subtitle:
              '${(staff.gercepRate * 100).toStringAsFixed(0)}% respons <= 2 jam',
          icon: Icons.bolt_rounded,
          color: const Color(0xFF059669),
          bg: const Color(0xFFECFDF5),
        ),
        _buildKpiCard(
          title: 'Total Jawaban',
          value: '${staff.answerCount}',
          subtitle: 'Pesan balasan solusi',
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.slate500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTagsCard(StaffPerformanceStat staff) {
    final tags = staff.tagCounts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined,
                  size: 16, color: Color(0xFF0F766E)),
              SizedBox(width: 6),
              Text(
                'Apresiasi & Tag Ulasan dari Pegawai',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tags.isEmpty)
            const Text(
              'Belum ada tag penilaian kepuasan spesifik untuk petugas ini.',
              style: TextStyle(fontSize: 11, color: AppColors.slate500),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.entries.map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF99F6E4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketHistoryCard(QuestionModel q) {
    return InkWell(
      onTap: q.id == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestionDetailScreen(question: q),
                ),
              );
            },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No Tiket & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  q.ticketNumber ?? 'TKT-${q.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.colorPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: q.isClosed
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: q.isClosed
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Text(
                    q.ticketStatus.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: q.isClosed
                          ? const Color(0xFF065F46)
                          : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Judul Pertanyaan
            Text(
              q.judul,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Tusi
            if (q.tugasFungsiNama != null)
              Text(
                q.tugasFungsiNama!,
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.slate500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.slate200),
            const SizedBox(height: 8),

            // Rating & Pemohon Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Info Kawasan
                Expanded(
                  child: Text(
                    q.lksdmKawasan ?? q.authorAsalLksdm,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.slate500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Star Rating jika sudah dinilai
                if (q.rating != null && q.rating! > 0)
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (starIdx) => Icon(
                          starIdx < q.rating!
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${q.rating}.0',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Belum dinilai',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.slate400),
                  ),
              ],
            ),

            if (q.ratingFeedback != null &&
                q.ratingFeedback!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '"${q.ratingFeedback}"',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
