import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AskQuestionPage extends StatefulWidget {
  final String token;

  const AskQuestionPage({
    super.key,
    required this.token,
  });

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController questionController = TextEditingController();

  String? selectedCategory;
  bool isSubmitting = false;

  final List<String> categories = [
    'Kenaikan Pangkat',
    'Kesejahteraan',
    'Mutasi',
    'Pengembangan Kompetensi',
    'Manajemen Kinerja',
    'Data dan Informasi SDM',
    'Lainnya',
  ];

  final Map<String, int> categoryTaskMap = {
    'Kenaikan Pangkat': 6,
    'Kesejahteraan': 10,
    'Mutasi': 7,
    'Pengembangan Kompetensi': 20,
    'Manajemen Kinerja': 30,
    'Data dan Informasi SDM': 90,
    'Lainnya': 1,
  };

  @override
  void dispose() {
    titleController.dispose();
    questionController.dispose();
    super.dispose();
  }

  Future<void> submitQuestion() async {
    if (titleController.text.trim().isEmpty) {
      showMessage('Judul pertanyaan harus diisi.');
      return;
    }

    if (selectedCategory == null) {
      showMessage('Pilih kategori pertanyaan.');
      return;
    }

    if (questionController.text.trim().isEmpty) {
      showMessage('Pertanyaan harus diisi.');
      return;
    }

    final tugasFungsiId = categoryTaskMap[selectedCategory!];

    if (tugasFungsiId == null) {
      showMessage('Tugas fungsi belum tersedia.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await ApiService.createQuestion(
        token: widget.token,
        judul: titleController.text.trim(),
        isi: questionController.text.trim(),
        tugasFungsiIds: [tugasFungsiId],
        isPublic: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pertanyaan berhasil diajukan.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Ajukan Pertanyaan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFC62828),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajukan Pertanyaan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Sampaikan pertanyaan seputar layanan kepegawaian BOSDM.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // JUDUL
            // =========================
            const Text(
              'Judul Pertanyaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Contoh: Bagaimana prosedur kenaikan pangkat?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // KATEGORI
            // =========================
            const Text(
              'Kategori',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                hintText: 'Pilih kategori',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // =========================
            // ISI PERTANYAAN
            // =========================
            const Text(
              'Pertanyaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: questionController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: 'Tuliskan pertanyaan Anda secara lengkap...',
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =========================
            // TOMBOL
            // =========================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submitQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Ajukan Pertanyaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
