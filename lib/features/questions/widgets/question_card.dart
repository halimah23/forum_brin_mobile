import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/question_model.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onTap;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String namaUser = question.user?.name ?? 'Pegawai';
    final String? namaTim = question.targetTim ??
        ((question.tugasFungsi != null && question.tugasFungsi!.isNotEmpty)
            ? question.tugasFungsi!.first.teamName ?? question.tugasFungsi!.first.nama
            : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.lightRedBackground,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaUser,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (question.ticketNumber != null)
                          Text(
                            question.ticketNumber!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: question.status),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: question.isPublic ? const Color(0xFFE8F5E9) : const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: question.isPublic ? const Color(0xFFA5D6A7) : const Color(0xFFCE93D8),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              question.isPublic ? Icons.public : Icons.lock_outline,
                              size: 10,
                              color: question.isPublic ? const Color(0xFF2E7D32) : const Color(0xFF7B1FA2),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              question.isPublic ? 'Publik' : 'Privat',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: question.isPublic ? const Color(0xFF2E7D32) : const Color(0xFF7B1FA2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (namaTim != null && namaTim.isNotEmpty && namaTim != '-')
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Tujuan: $namaTim',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                question.judul,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question.isi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (question.answers != null && question.answers!.isNotEmpty)
                            ? '${question.answers!.length} Jawaban Resmi'
                            : 'Lihat Detail Tiket',
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (question.assignedTo != null && question.assignedTo!.isNotEmpty)
                    Text(
                      'Petugas: ${question.assignedTo}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
