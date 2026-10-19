import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../../questions/models/question_model.dart';

class AuditQuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onTap;
  final VoidCallback? onReopen;

  const AuditQuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    this.onReopen,
  });

  bool _isExceedingSla() {
    if (question.isClosed) return false;
    if (question.createdAt == null) return false;
    try {
      final created = DateTime.parse(question.createdAt!);
      final diffHours = DateTime.now().difference(created).inHours;
      return diffHours >= 24 && (question.answers == null || question.answers!.isEmpty);
    } catch (_) {
      return false;
    }
  }

  String _formatTime() {
    if (question.createdAt == null) return '-';
    try {
      final dt = DateTime.parse(question.createdAt!).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return question.createdAt!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverSla = _isExceedingSla();
    final String pelaporNama = question.user?.name ?? 'Pegawai BRIN';
    final String? pelaporUnit = question.user?.unit;
    final String kawasanLksdm = question.lksdmKawasan ?? question.lksdmWilayah ?? 'LKSDM Kawasan';
    final String timPusat = question.targetTimPusat ?? question.targetTim ?? 'Tim Pusat';
    final int answerCount = question.answers?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isOverSla ? AppColors.warning : AppColors.border,
          width: isOverSla ? 1.5 : 1,
        ),
        boxShadow: isOverSla
            ? [
                BoxShadow(
                  color: AppColors.warning.withAlpha(20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Nomor Tiket, Badge Privasi, Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF512DA8).withAlpha(18),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: const Color(0xFF512DA8).withAlpha(40)),
                      ),
                      child: Text(
                        question.ticketNumber ?? '#TKT-${question.id ?? 0}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF512DA8),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: question.isPublic ? AppColors.primaryBlue.withAlpha(15) : AppColors.slate200,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            question.isPublic ? Icons.public : Icons.lock_outline,
                            size: 11,
                            color: question.isPublic ? AppColors.primaryBlue : AppColors.slate700,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            question.isPublic ? 'PUBLIK' : 'PRIVAT',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: question.isPublic ? AppColors.primaryBlue : AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (question.isStandardized) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF512DA8).withAlpha(18),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_fix_high_rounded, size: 10, color: Color(0xFF512DA8)),
                            SizedBox(width: 3),
                            Text(
                              'DIBAKUKAN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF512DA8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    StatusBadge(status: question.status),
                  ],
                ),
                const SizedBox(height: 10),

                // Indikator SLA / Durasi Waktu Respon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverSla ? AppColors.warningBackground : AppColors.slate50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isOverSla ? AppColors.warning.withAlpha(50) : AppColors.slate200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOverSla ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                        size: 13,
                        color: isOverSla ? AppColors.warning : AppColors.slate600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isOverSla
                              ? 'Perhatian: Belum direspon > 24 jam (Melebihi SLA)'
                              : (question.isClosed
                                  ? 'SLA Selesai • Tiket Ditutup'
                                  : 'SLA Normal • Terpantau Sistem'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isOverSla ? FontWeight.bold : FontWeight.w500,
                            color: isOverSla ? AppColors.warning : AppColors.slate700,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(),
                        style: const TextStyle(fontSize: 10, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Judul Pertanyaan
                Text(
                  question.judul,
                  style: AppTypography.heading3.copyWith(fontSize: 14.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Info Pelapor
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.slate500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        (question.isPublic || question.isAnonymized)
                            ? (pelaporUnit != null && pelaporUnit.isNotEmpty
                                ? '$pelaporNama ($pelaporUnit) • Publik: Pegawai'
                                : '$pelaporNama • Publik: Pegawai')
                            : (pelaporUnit != null && pelaporUnit.isNotEmpty
                                ? '$pelaporNama ($pelaporUnit)'
                                : pelaporNama),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.slate600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Alur Audit Layanan (LKSDM -> Tim Pusat)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF512DA8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$kawasanLksdm ➔ $timPusat',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),

                // Footer: Staf PIC & Jumlah Tanggapan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, size: 14, color: AppColors.slate500),
                        const SizedBox(width: 4),
                        Text(
                          question.assignedTo != null && question.assignedTo!.isNotEmpty
                              ? 'PIC: ${question.assignedTo}'
                              : 'PIC: Belum Ditugaskan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: question.assignedTo != null ? AppColors.slate800 : AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.forum_outlined, size: 13, color: AppColors.slate500),
                        const SizedBox(width: 4),
                        Text(
                          '$answerCount respon',
                          style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.slate400),
                      ],
                    ),
                  ],
                ),
                if (question.isClosed && onReopen != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            Text(
                              'Tiket berstatus Selesai',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          ),
                          icon: const Icon(Icons.replay_rounded, size: 13),
                          label: const Text('Buka Kembali', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          onPressed: onReopen,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
