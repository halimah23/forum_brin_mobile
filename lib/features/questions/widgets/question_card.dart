import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../models/question_model.dart';
import '../../../core/widgets/status_badge.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onTap;
  final UserModel? currentUser;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final namaUser = question.user?.name ?? 'Pegawai';
    final initial = namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'P';
    final answerCount = question.answers?.length ?? 0;
    final namaTim = question.targetTimPusat ?? question.targetTim;

    // Logika Privasi Identitas:
    final currentRole = currentUser?.userRole ?? UserRole.member;
    final bool isPrivilegedRole = currentRole != UserRole.member;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.colorBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F366A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.colorPrimarySoft,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.colorPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPrivilegedRole ? question.officialAuthorName : namaUser,
                            style: AppTypography.labelMedium.copyWith(color: AppColors.colorText),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (question.ticketNumber != null)
                            Text(
                              question.ticketNumber!,
                              style: AppTypography.caption.copyWith(color: AppColors.colorTextMuted),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          if (isPrivilegedRole)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_city_rounded,
                                    size: 11,
                                    color: AppColors.colorTextMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Asal: ${question.authorAsalLksdm}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.colorTextMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(status: question.status, useShortLabel: true),
                        if (question.isMandiriLksdm) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.colorSecondarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.colorSecondary.withAlpha(80), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.badge_outlined, size: 10, color: AppColors.colorSecondaryStrong),
                                SizedBox(width: 3),
                                Text(
                                  'KONSULTASI LKSDM',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.colorSecondaryStrong,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (namaTim != null && namaTim.isNotEmpty && namaTim != '-')
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.colorPrimarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.colorPrimary.withAlpha(40), width: 1),
                    ),
                    child: Text(
                      'Tujuan: $namaTim',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.colorPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  question.judul,
                  style: AppTypography.heading3.copyWith(
                    fontSize: 14,
                    color: AppColors.colorText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.colorTextMuted),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.colorBorder),
                const SizedBox(height: 8),
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
                            color: AppColors.colorTextMuted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              answerCount > 0
                                  ? '$answerCount Tanggapan'
                                  : 'Belum ada tanggapan',
                              style: AppTypography.caption.copyWith(
                                color: answerCount > 0 ? AppColors.colorText : AppColors.colorTextMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (question.assignedTo != null && question.assignedTo!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Petugas: ${question.assignedTo}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.colorTextMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
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
