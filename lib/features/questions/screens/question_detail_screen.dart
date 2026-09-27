import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/question_model.dart';

class QuestionDetailScreen extends StatelessWidget {
  final QuestionModel question;

  const QuestionDetailScreen({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final String namaUser = question.user?.name ?? 'Pegawai';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Detail Pertanyaan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KARTU PERTANYAAN
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            StatusBadge(
                              status: question.status,
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Text(
                          question.judul,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          question.isi,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Divider(),

                        const SizedBox(height: 8),

                        const Row(
                          children: [
                            Icon(
                              Icons.account_tree_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tujuan: Tim terkait BOSDM',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // JUDUL DISKUSI
                const Text(
                  'Diskusi dan Jawaban',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // CONTOH JIKA BELUM ADA JAWABAN
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Belum ada jawaban untuk pertanyaan ini.',
                            style: TextStyle(
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
