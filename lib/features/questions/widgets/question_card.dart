import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../models/question_model.dart';

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

  bool get isPrivilegedRole {
    if (currentUser == null) return false;
    return currentUser!.isAdminLksdm ||
        currentUser!.isAdminPusat ||
        currentUser!.isKetuaTim ||
        currentUser!.isEksekutif ||
        currentUser!.isSuperAdmin ||
        currentUser!.userRole == UserRole.admin ||
        currentUser!.userRole == UserRole.adminLksdm ||
        currentUser!.userRole == UserRole.adminPusat ||
        currentUser!.userRole == UserRole.ketuaTim ||
        currentUser!.userRole == UserRole.eksekutif ||
        currentUser!.userRole == UserRole.superAdmin;
  }

  @override
  Widget build(BuildContext context) {
    final String namaUser = question.getAuthorDisplayName(currentUser);
    final String initial = question.getAuthorInitial(currentUser);
    final String? namaTim = question.targetTim ??
        ((question.tugasFungsi != null && question.tugasFungsi!.isNotEmpty)
            ? question.tugasFungsi!.first.teamName ?? question.tugasFungsi!.first.nama
            : null);

    final int answerCount = question.answers?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
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
                      backgroundColor: AppColors.primaryRed,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
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
                            style: AppTypography.labelMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (question.ticketNumber != null)
                            Text(
                              question.ticketNumber!,
                              style: AppTypography.caption,
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
                                    color: AppColors.slate600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Asal: ${question.authorAsalLksdm}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate700,
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.slate300, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                question.isPublic ? Icons.public : Icons.lock_outline,
                                size: 10,
                                color: AppColors.slate700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                question.isPublic ? 'Publik' : 'Privat',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate700,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: Text(
                      'Tujuan: $namaTim',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  question.judul,
                  style: AppTypography.heading3.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  question.isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
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
                            color: AppColors.slate500,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              answerCount > 0
                                  ? '$answerCount Tanggapan'
                                  : 'Belum ada tanggapan',
                              style: AppTypography.caption.copyWith(
                                color: answerCount > 0 ? AppColors.slate700 : AppColors.slate500,
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
                            color: AppColors.slate600,
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

