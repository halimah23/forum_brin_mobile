import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../models/question_model.dart';

class ForumDiscussionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final bool isProcessingPin;
  final UserModel? currentUser;

  const ForumDiscussionCard({
    super.key,
    required this.question,
    required this.onTap,
    required this.onTogglePin,
    this.isProcessingPin = false,
    this.currentUser,
  });

  String _formatDate() {
    if (question.createdAt == null) return '';
    try {
      final dt = DateTime.parse(question.createdAt!).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 7) {
        return '${dt.day}/${dt.month}/${dt.year}';
      } else if (diff.inDays > 0) {
        return '${diff.inDays} hari lalu';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} jam lalu';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} mnt lalu';
      } else {
        return 'Baru saja';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String authorName = question.getAuthorDisplayName(currentUser);
    final String initial = question.getAuthorInitial(currentUser);
    final int answerCount = question.answers?.length ?? 0;
    final bool hasOfficialAnswer = question.answers?.any((a) => a.isOfficial) ?? false;
    final String topikKategori = question.tugasFungsiNama ??
        ((question.tugasFungsi != null && question.tugasFungsi!.isNotEmpty)
            ? (question.tugasFungsi!.first.teamName ?? question.tugasFungsi!.first.nama)
            : 'Kepegawaian Umum');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: question.isPinned ? Colors.amber.shade400 : AppColors.border,
          width: question.isPinned ? 1.5 : 1,
        ),
        boxShadow: question.isPinned
            ? [
                BoxShadow(
                  color: Colors.amber.withAlpha(25),
                  blurRadius: 8,
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
                // Top Row: Avatar, Penulis, Tanggal, & Pin Quick Action
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: question.isPinned ? Colors.amber.shade700 : AppColors.primaryRed,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: AppTypography.labelMedium.copyWith(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(),
                            style: const TextStyle(fontSize: 10.5, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                    if (question.isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin, size: 11, color: Colors.amber.shade800),
                            const SizedBox(width: 3),
                            Text(
                              'FAQ TREN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Quick Action: Superadmin Pin / Unpin
                    InkWell(
                      onTap: isProcessingPin ? null : onTogglePin,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: isProcessingPin
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                              )
                            : Icon(
                                question.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                size: 20,
                                color: question.isPinned ? Colors.amber.shade700 : AppColors.slate400,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Kategori Topik Tag & Badge Pembakuan (Responsif)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        topikKategori,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (question.isStandardized)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF512DA8).withAlpha(15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_fix_high_rounded, size: 10, color: Color(0xFF512DA8)),
                            SizedBox(width: 3),
                            Text(
                              'Telah Dibakukan',
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
                ),
                const SizedBox(height: 6),

                // Judul Topik
                Text(
                  question.judul,
                  style: AppTypography.heading3.copyWith(fontSize: 14.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Cuplikan Isi Pertanyaan
                Text(
                  question.isi,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate700, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Highlight Jawaban Resmi jika ada
                if (hasOfficialAnswer) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successBackground,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.success.withAlpha(50)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 13, color: AppColors.success),
                        SizedBox(width: 5),
                        Text(
                          'Tersedia Tanggapan Resmi Tim SDM',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),

                // Footer: Diskusi Count & Aksi Baca
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: AppColors.slate500,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              answerCount > 0
                                  ? '$answerCount Diskusi'
                                  : 'Belum ada tanggapan',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: answerCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                color: answerCount > 0 ? AppColors.slate800 : AppColors.slate500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buka Diskusi',
                          style: TextStyle(fontSize: 11.5, color: AppColors.primaryRed, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primaryRed),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
