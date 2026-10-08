import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../cubits/ask_question_cubit.dart';
import '../cubits/ask_question_state.dart';
import '../data/lksdm_catalog_data.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import 'question_detail_screen.dart';

class AskQuestionScreen extends StatelessWidget {
  final String token;
  final bool isTab;
  final VoidCallback? onSuccess;

  const AskQuestionScreen({
    super.key,
    required this.token,
    this.isTab = false,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AskQuestionCubit(),
      child: AskQuestionView(
        token: token,
        isTab: isTab,
        onSuccess: onSuccess,
      ),
    );
  }
}

class AskQuestionView extends StatefulWidget {
  final String token;
  final bool isTab;
  final VoidCallback? onSuccess;

  const AskQuestionView({
    super.key,
    required this.token,
    this.isTab = false,
    this.onSuccess,
  });

  @override
  State<AskQuestionView> createState() => _AskQuestionViewState();
}

class _AskQuestionViewState extends State<AskQuestionView> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final questionController = TextEditingController();
  final titleFocusNode = FocusNode();
  final questionFocusNode = FocusNode();

  final List<LksdmItem> lksdmList = LksdmCatalogData.allLksdm;
  late LksdmItem selectedLksdm;

  QuestionModel? activeTicket;
  bool dismissActiveBanner = false;

  @override
  void initState() {
    super.initState();
    selectedLksdm = lksdmList.first;
    _checkActiveTicket();
  }

  void _checkActiveTicket() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '77777777-7777-7777-7777-777777777777';
    final ticket = await QuestionService.getUserActiveTicket(
      userId: userId,
      lksdmKawasan: selectedLksdm.shortName,
    );
    if (mounted) {
      setState(() {
        activeTicket = ticket;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    questionController.dispose();
    titleFocusNode.dispose();
    questionFocusNode.dispose();
    super.dispose();
  }

  void submitQuestion() async {
    if (_formKey.currentState?.validate() ?? false) {
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
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: AppColors.slate900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lksdmClean = selectedLksdm.shortName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        automaticallyImplyLeading: !widget.isTab,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanya Kepegawaian',
              style: AppTypography.heading3,
            ),
            Text(
              'Ruang Pengajuan Pertanyaan ($lksdmClean)',
              style: AppTypography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: BlocConsumer<AskQuestionCubit, AskQuestionState>(
        listener: (context, state) {
          if (state is AskQuestionSuccess) {
            titleController.clear();
            questionController.clear();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pertanyaan berhasil dikirim ke Staf Admin $lksdmClean.',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
            );

            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else if (!widget.isTab && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          } else if (state is AskQuestionError) {
            showMessage(state.message);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is AskQuestionSubmitting;

          return SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Intro Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.border, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate100,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: const Icon(
                                        Icons.support_agent_rounded,
                                        size: 20,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Silakan pilih kawasan LKSDM dan sampaikan konsultasi kepegawaian Anda di bawah ini.',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              if (activeTicket != null && !dismissActiveBanner) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Anda Memiliki Tiket Aktif Berjalan',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => setState(() => dismissActiveBanner = true),
                                            child: const Icon(Icons.close, size: 18, color: Color(0xFF92400E)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${activeTicket!.ticketNumber} - ${activeTicket!.judul}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate900),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          StatusBadge(status: activeTicket!.status),
                                          const Spacer(),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => QuestionDetailScreen(question: activeTicket!),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                            label: const Text('Lanjutkan Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // 1. LKSDM Selector
                              const Text(
                                '1. Wilayah Kerja LKSDM',
                                style: AppTypography.labelMedium,
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<LksdmItem>(
                                initialValue: selectedLksdm,
                                isExpanded: true,
                                style: AppTypography.bodyMedium,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.slate500, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                                  ),
                                ),
                                items: lksdmList.map((item) {
                                  return DropdownMenuItem<LksdmItem>(
                                    value: item,
                                    child: Text(
                                      item.name,
                                      style: AppTypography.bodyMedium,
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
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: AppColors.border, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: AppColors.slate500),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cakupan: ${selectedLksdm.coverageUnits.join(", ")}',
                                        style: AppTypography.caption,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 2. Judul Pertanyaan Input
                              CustomTextField(
                                controller: titleController,
                                focusNode: titleFocusNode,
                                label: '2. Judul Pertanyaan',
                                hintText: 'Contoh: Prosedur Uji Kompetensi Kenaikan Jabatan...',
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  questionFocusNode.requestFocus();
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Judul pertanyaan wajib diisi';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // 3. Detail Pertanyaan Input
                              CustomTextField(
                                controller: questionController,
                                focusNode: questionFocusNode,
                                label: '3. Uraian Pertanyaan Lengkap',
                                hintText: 'Jelaskan pertanyaan atau kendala yang Anda hadapi secara rinci...',
                                maxLines: 5,
                                textInputAction: TextInputAction.newline,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Isi pertanyaan wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action CTA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: CustomButton(
                          text: 'Kirim Pertanyaan',
                          onPressed: submitQuestion,
                          isLoading: isSubmitting,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
