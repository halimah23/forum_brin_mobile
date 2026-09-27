import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'ask_question_page.dart';
import 'question_detail_page.dart';

class QuestionListPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const QuestionListPage({
    super.key,
    required this.user,
  });

  @override
  State<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends State<QuestionListPage> {
  List<dynamic> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final data = await ApiService.getQuestions(
        token: widget.user['token'].toString(),
      );

      if (!mounted) return;

      setState(() {
        questions = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Tanya Jawab',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CABFF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC62828),
                  ),
                )
              : questions.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada pertanyaan.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadQuestions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];

                          return QuestionCard(
                            question: question,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuestionDetailPage(
                                    question: question,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC62828),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AskQuestionPage(
                token: widget.user['token'].toString(),
              ),
            ),
          );

          if (!mounted) return;

          loadQuestions();
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onTap;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onTap,
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
                    backgroundColor: Color(0xFFFFEBEE),
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
                      ),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isi,
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
                      color: Color(0xFFC62828),
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