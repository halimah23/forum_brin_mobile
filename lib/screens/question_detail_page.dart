import 'package:flutter/material.dart';

class QuestionDetailPage extends StatelessWidget {
  final Map<String, dynamic> question;

  const QuestionDetailPage({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final String judul =
        question['judul']?.toString() ?? '-';

    final String isi =
        question['isi']?.toString() ?? '-';

    final String status =
        question['status']?.toString() ?? '-';

    final userData = question['user'];

    final String namaUser = userData is Map
        ? userData['name']?.toString() ?? 'Pegawai'
        : 'Pegawai';

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
        backgroundColor: const Color(0xFFC62828),
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor:
                                  Color(0xFFFFEBEE),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFFC62828),
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
                            _StatusBadge(
                              status: status,
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Text(
                          judul,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          isi,
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String label;

    switch (status) {
      case 'diajukan':
        label = 'Diajukan';
        break;
      case 'diproses':
        label = 'Diproses';
        break;
      case 'dijawab':
        label = 'Dijawab';
        break;
      case 'selesai':
        label = 'Selesai';
        break;
      case 'ditolak':
        label = 'Ditolak';
        break;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFC62828),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}