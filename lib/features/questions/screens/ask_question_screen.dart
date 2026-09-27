import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../cubits/ask_question_cubit.dart';
import '../cubits/ask_question_state.dart';

class AskQuestionScreen extends StatelessWidget {
  final String token;

  const AskQuestionScreen({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AskQuestionCubit(),
      child: AskQuestionView(token: token),
    );
  }
}

class AskQuestionView extends StatefulWidget {
  final String token;

  const AskQuestionView({super.key, required this.token});

  @override
  State<AskQuestionView> createState() => _AskQuestionViewState();
}

class _AskQuestionViewState extends State<AskQuestionView> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController questionController = TextEditingController();

  String? selectedCategory;

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

  void submitQuestion() {
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

    context.read<AskQuestionCubit>().submitQuestion(
          token: widget.token,
          judul: titleController.text.trim(),
          isi: questionController.text.trim(),
          tugasFungsiIds: [tugasFungsiId],
        );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Ajukan Pertanyaan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryRed,
          ),
        ),
      ),
      body: BlocConsumer<AskQuestionCubit, AskQuestionState>(
        listener: (context, state) {
          if (state is AskQuestionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pertanyaan berhasil diajukan.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is AskQuestionError) {
            showMessage(state.message);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is AskQuestionSubmitting;

          return SingleChildScrollView(
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
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // JUDUL
                const Text(
                  'Judul Pertanyaan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: titleController,
                  hintText: 'Contoh: Bagaimana prosedur kenaikan pangkat?',
                ),
                const SizedBox(height: 20),
                
                // KATEGORI
                const Text(
                  'Kategori',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
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
                
                // ISI PERTANYAAN
                const Text(
                  'Pertanyaan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: questionController,
                  hintText: 'Tuliskan pertanyaan Anda secara lengkap...',
                  maxLines: 7,
                ),
                const SizedBox(height: 28),
                
                CustomButton(
                  text: 'Ajukan Pertanyaan',
                  onPressed: submitQuestion,
                  isLoading: isSubmitting,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
