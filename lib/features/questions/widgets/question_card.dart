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
                    child: Text(
                      namaUser,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: question.status),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                question.judul,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question.isi,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Lihat diskusi',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w600,
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
