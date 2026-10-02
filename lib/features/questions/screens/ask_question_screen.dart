import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../cubits/ask_question_cubit.dart';
import '../cubits/ask_question_state.dart';
import '../data/lksdm_catalog_data.dart';

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

  final List<LksdmItem> lksdmList = LksdmCatalogData.allLksdm;
  late LksdmItem selectedLksdm;

  @override
  void initState() {
    super.initState();
    selectedLksdm = lksdmList.first;
  }

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
    if (questionController.text.trim().isEmpty) {
      showMessage('Isi pertanyaan harus diisi.');
      return;
    }

    final lksdmClean = selectedLksdm.shortName;

    context.read<AskQuestionCubit>().submitQuestion(
          token: widget.token,
          judul: titleController.text.trim(),
          isi: questionController.text.trim(),
          selectedTeam: lksdmClean,
          lksdmKawasan: lksdmClean,
          tugasFungsiIds: const [],
          isPublic: true,
        );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lksdmClean = selectedLksdm.shortName;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanya Kepegawaian',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              'Ruang Pengajuan Pertanyaan (${selectedLksdm.shortName})',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: BlocConsumer<AskQuestionCubit, AskQuestionState>(
        listener: (context, state) {
          if (state is AskQuestionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pertanyaan berhasil dikirim ke Staf Admin $lksdmClean.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is AskQuestionError) {
            showMessage(state.message);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is AskQuestionSubmitting;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. SYSTEM GREETING BUBBLE (Sisi Kiri)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14, right: 36),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  border: Border.all(color: Colors.teal.shade200, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.teal.shade50,
                                          child: Icon(Icons.support_agent, size: 14, color: Colors.teal.shade800),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Staf Admin Forum BOSDM',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Halo Pegawai BRIN! Selamat datang di layanan Tanya Kepegawaian. Silakan tentukan kawasan LKSDM Anda dan isi detail pertanyaan pada bubble pesan di bawah ini.',
                                      style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. BUBBLE PILIHAN WILAYAH LKSDM (Sisi Kiri - System Card)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 18, right: 24),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  border: Border.all(color: AppColors.primaryRed.withAlpha(80), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(6),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.location_city, size: 16, color: AppColors.primaryRed),
                                        SizedBox(width: 6),
                                        Text(
                                          '1. Wilayah Kerja / Kawasan LKSDM Anda',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<LksdmItem>(
                                      value: selectedLksdm,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        hintText: 'Pilih Wilayah LKSDM',
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primaryRed, size: 18),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      items: lksdmList.map((item) {
                                        return DropdownMenuItem<LksdmItem>(
                                          value: item,
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedLksdm = value;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFA5D6A7)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.auto_mode, size: 16, color: Color(0xFF2E7D32)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Otomatis ditangani oleh Staf Admin ${selectedLksdm.shortName}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Cakupan Unit: ${selectedLksdm.coverageUnits.join(", ")}',
                                            style: const TextStyle(fontSize: 10, color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 3. DRAFT PERTANYAAN PEGAWAI (Sisi Kanan - User Speech Bubble)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16, left: 24),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  border: Border.all(color: const Color(0xFFBBDEFB), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(5),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.person, size: 16, color: Color(0xFF1565C0)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Pegawai BRIN (Anda)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // INPUT JUDUL PERTANYAAN
                                    const Text(
                                      '2. Judul Pertanyaan',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: titleController,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Contoh: Prosedur Uji Kompetensi Kenaikan Jabatan...',
                                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // INPUT URAIAN LENGKAP PERTANYAAN
                                    const Text(
                                      '3. Uraian Lengkap Pertanyaan',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: questionController,
                                      maxLines: 5,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Jelaskan pertanyaan atau kendala yang Anda hadapi secara rinci...',
                                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.all(12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
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
                ),

                // 4. BOTTOM MESSAGING ACTION BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: isSubmitting ? null : submitQuestion,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          isSubmitting ? 'Mengirim Tiket...' : 'Kirim & Buat Tiket Pertanyaan',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
