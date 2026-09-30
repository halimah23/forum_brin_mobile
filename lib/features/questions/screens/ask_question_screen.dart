import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../cubits/ask_question_cubit.dart';
import '../cubits/ask_question_state.dart';
import '../data/tusi_catalog_data.dart';
import '../models/category_model.dart';
import '../services/question_service.dart';

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

  List<String> teamList = [];
  String? selectedTeam;

  List<CategoryModel> availableTusiList = [];
  CategoryModel? selectedTusi;
  bool isLoadingTeams = true;
  bool isPublic = true; // Default Publik

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await QuestionService.getTeams();
      if (mounted) {
        setState(() {
          teamList = teams;
          if (teams.isNotEmpty) {
            selectedTeam = teams.first;
            _updateTusiForTeam(teams.first);
          }
          isLoadingTeams = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          teamList = TusiCatalogData.allTeams;
          selectedTeam = teamList.first;
          _updateTusiForTeam(selectedTeam!);
          isLoadingTeams = false;
        });
      }
    }
  }

  void _updateTusiForTeam(String team) async {
    setState(() {
      selectedTusi = null;
    });

    final list = await QuestionService.getTugasFungsi(teamName: team);
    if (mounted) {
      setState(() {
        availableTusiList = list;
        if (list.isNotEmpty) {
          selectedTusi = list.first;
        }
      });
    }
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
    if (selectedTeam == null || selectedTeam!.isEmpty) {
      showMessage('Silakan pilih Tim BOSDM tujuan.');
      return;
    }
    if (selectedTusi == null) {
      showMessage('Silakan pilih kode/topik Tugas & Fungsi terkait.');
      return;
    }
    if (questionController.text.trim().isEmpty) {
      showMessage('Isi pertanyaan harus diisi.');
      return;
    }

    context.read<AskQuestionCubit>().submitQuestion(
          token: widget.token,
          judul: titleController.text.trim(),
          isi: questionController.text.trim(),
          selectedTeam: selectedTeam,
          tugasFungsiIds: [selectedTusi!.id],
          isPublic: isPublic,
        );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openSearchableTusiPicker() async {
    final searchController = TextEditingController();
    List<CategoryModel> filteredList = List.from(availableTusiList);

    final CategoryModel? picked = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, color: AppColors.primaryRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pilih Layanan Tusi: $selectedTeam',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau kode Tusi...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            filteredList = availableTusiList.where((item) {
                              final q = val.toLowerCase();
                              return item.nama.toLowerCase().contains(q) ||
                                  (item.kode?.toLowerCase().contains(q) ?? false);
                            }).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredList.isEmpty
                            ? const Center(
                                child: Text('Tidak ada layanan Tusi yang sesuai'),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filteredList.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filteredList[index];
                                  final isSelected = item.id == selectedTusi?.id;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    title: Text(
                                      item.nama,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? AppColors.primaryRed : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: item.kode != null
                                        ? Text(
                                            item.kode!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          )
                                        : null,
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle, color: AppColors.primaryRed)
                                        : null,
                                    onTap: () {
                                      Navigator.pop(ctx, item);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTusi = picked;
      });
    }
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
          'Buat Tiket Pertanyaan',
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
                content: Text('Tiket pertanyaan berhasil diajukan dan diteruskan ke antrean Ketua Tim terkait.'),
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
                  'Formulir Pengajuan Tiket Layanan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pertanyaan akan dibuatkan nomor tiket dan disalurkan ke Tim BOSDM yang berwenang untuk diverifikasi & dijawab.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // TINGKAT 1: PILIH TIM LAYANAN BOSDM
                const Text(
                  '1. Tim Layanan BOSDM Tujuan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (isLoadingTeams)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedTeam,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Pilih Tim BOSDM',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.groups_outlined, color: AppColors.primaryRed),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: teamList.map((team) {
                      return DropdownMenuItem<String>(
                        value: team,
                        child: Text(
                          team,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedTeam = value;
                        });
                        _updateTusiForTeam(value);
                      }
                    },
                  ),

                const SizedBox(height: 18),

                // TINGKAT 2: PILIH SUB-LAYANAN / KODE TUSI
                const Text(
                  '2. Bidang Layanan / Kode Tugas & Fungsi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openSearchableTusiPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: selectedTusi != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedTusi!.nama,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (selectedTusi!.kode != null)
                                      Text(
                                        selectedTusi!.kode!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                )
                              : const Text(
                                  'Ketuk untuk memilih topik Tusi...',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                // CARD ROUTING INDIKATOR
                if (selectedTeam != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 20,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              children: [
                                const TextSpan(text: 'Tiket akan masuk antrean '),
                                TextSpan(
                                  text: 'Ketua $selectedTeam',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const TextSpan(text: ' untuk diverifikasi, didisposisikan, atau dijawab langsung.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // SIFAT & VISIBILITAS PERTANYAAN (PUBLIK VS PRIVAT)
                const Text(
                  '3. Sifat & Visibilitas Pertanyaan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // OPSI PUBLIK
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => isPublic = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPublic ? const Color(0xFFE8F5E9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPublic ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                              width: isPublic ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.public,
                                    size: 18,
                                    color: isPublic ? const Color(0xFF2E7D32) : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Publik',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isPublic ? const Color(0xFF2E7D32) : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Dapat dibaca oleh semua pegawai di Forum Publik.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPublic ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // OPSI PRIVAT
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => isPublic = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !isPublic ? const Color(0xFFF3E5F5) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !isPublic ? const Color(0xFF7B1FA2) : Colors.grey.shade300,
                              width: !isPublic ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                    color: !isPublic ? const Color(0xFF7B1FA2) : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Privat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: !isPublic ? const Color(0xFF7B1FA2) : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rahasia. Hanya Ketua Tim tujuan yang dapat melihat.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: !isPublic ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // JUDUL PERTANYAAN
                const Text(
                  '4. Judul Pertanyaan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: titleController,
                  hintText: 'Contoh: Prosedur Uji Kompetensi Kenaikan Jabatan...',
                ),

                const SizedBox(height: 20),

                // ISI PERTANYAAN
                const Text(
                  '5. Uraian Lengkap Pertanyaan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: questionController,
                  hintText: 'Jelaskan pertanyaan atau kendala yang Anda hadapi secara rinci...',
                  maxLines: 6,
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: 'Kirim & Buat Tiket Pertanyaan',
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
