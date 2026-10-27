import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/storage/session_manager.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/models/user_model.dart';
import '../cubits/ask_question_cubit.dart';
import '../cubits/ask_question_state.dart';
import '../data/lksdm_catalog_data.dart';
import '../data/tusi_catalog_data.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import '../widgets/attachment_picker_widget.dart';
import 'question_detail_screen.dart';

class AskQuestionScreen extends StatelessWidget {
  final String token;
  final bool isTab;
  final VoidCallback? onSuccess;
  final UserModel? user;
  final bool isLksdmConsultation;

  const AskQuestionScreen({
    super.key,
    required this.token,
    this.isTab = false,
    this.onSuccess,
    this.user,
    this.isLksdmConsultation = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AskQuestionCubit(),
      child: AskQuestionView(
        token: token,
        isTab: isTab,
        onSuccess: onSuccess,
        user: user,
        isLksdmConsultation: isLksdmConsultation,
      ),
    );
  }
}

class AskQuestionView extends StatefulWidget {
  final String token;
  final bool isTab;
  final VoidCallback? onSuccess;
  final UserModel? user;
  final bool isLksdmConsultation;

  const AskQuestionView({
    super.key,
    required this.token,
    this.isTab = false,
    this.onSuccess,
    this.user,
    this.isLksdmConsultation = false,
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
  late String selectedPusatTeam;

  QuestionModel? activeTicket;
  bool dismissActiveBanner = false;
  String? attachedFileUrl;
  String? attachedFileName;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    selectedLksdm = lksdmList.first;
    selectedPusatTeam = TusiCatalogData.centralTeams.first;
    _resolveUserAndLksdm();
  }

  void _resolveUserAndLksdm() async {
    currentUser ??= await SessionManager.getUser();
    final lksdmShort = currentUser?.effectiveLksdm ?? 'LKSDM 1';
    final matched = lksdmList.firstWhere(
      (item) => item.shortName.toUpperCase() == lksdmShort.toUpperCase(),
      orElse: () => lksdmList.firstWhere(
        (item) => item.name.toUpperCase().contains(lksdmShort.toUpperCase()),
        orElse: () => lksdmList.first,
      ),
    );
    if (mounted) {
      setState(() {
        selectedLksdm = matched;
      });
      if (!widget.isLksdmConsultation) {
        _checkActiveTicket();
      }
    }
  }

  void _checkActiveTicket() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? currentUser?.id ?? 'usr_240';
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
      if (attachedFileUrl != null &&
          attachedFileUrl!.isNotEmpty &&
          !(attachedFileUrl!.startsWith('http://') || attachedFileUrl!.startsWith('https://'))) {
        showMessage('Berkas lampiran belum tersimpan di Cloud Storage. Silakan lampirkan ulang.');
        return;
      }

      final lksdmClean = selectedLksdm.shortName;
      final isConsultation = widget.isLksdmConsultation;

      context.read<AskQuestionCubit>().submitQuestion(
            token: widget.token,
            judul: titleController.text.trim(),
            isi: questionController.text.trim(),
            selectedTeam: isConsultation ? selectedPusatTeam : lksdmClean,
            lksdmKawasan: lksdmClean,
            targetTimPusat: isConsultation ? selectedPusatTeam : null,
            tugasFungsiIds: const [],
            isPublic: false,
            attachmentUrl: attachedFileUrl,
            attachmentName: attachedFileName,
            isLksdmConsultation: isConsultation,
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
    final isConsultation = widget.isLksdmConsultation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !widget.isTab,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isConsultation ? 'Konsultasi ke Tim Pusat' : 'Tanya Kepegawaian',
              style: AppTypography.heading3,
            ),
            Text(
              isConsultation
                  ? 'Konsultasi Teknis & Regulasi ($lksdmClean ➔ Pusat)'
                  : 'Ruang Pengajuan Pertanyaan ($lksdmClean)',
              style: AppTypography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: BlocConsumer<AskQuestionCubit, AskQuestionState>(
        listener: (context, state) {
          if (state is AskQuestionSuccess) {
            titleController.clear();
            questionController.clear();
            
            final successMsg = isConsultation
                ? 'Konsultasi berhasil diteruskan langsung ke $selectedPusatTeam.'
                : 'Pertanyaan berhasil dikirim ke Staf Admin $lksdmClean.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  successMsg,
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
              Navigator.pop(context, true);
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
                              if (activeTicket != null && !dismissActiveBanner && !isConsultation) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Anda Memiliki Tiket Aktif di Kawasan Ini',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Color(0xFF92400E)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => setState(() => dismissActiveBanner = true),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tiket #${activeTicket!.ticketNumber ?? activeTicket!.id}: "${activeTicket!.judul}" saat ini masih berjalan.',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF92400E),
                                            side: const BorderSide(color: Color(0xFFD97706)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                          ),
                                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                                          label: const Text('Buka Percakapan Tiket Berjalan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => QuestionDetailScreen(
                                                  question: activeTicket!,
                                                  currentUser: currentUser,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // 1. Wilayah Asal Pengajuan LKSDM
                              Text(
                                isConsultation ? '1. Asal Kawasan LKSDM Pengaju' : '1. Wilayah Penanganan Kawasan SDM',
                                style: AppTypography.labelMedium,
                              ),
                              const SizedBox(height: 6),
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
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isConsultation ? AppColors.colorSecondarySoft : AppColors.colorPrimarySoft,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Icon(
                                        isConsultation ? Icons.badge_outlined : Icons.location_on_rounded,
                                        size: 22,
                                        color: isConsultation ? AppColors.colorSecondaryStrong : AppColors.colorPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                selectedLksdm.shortName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.slate900,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isConsultation ? Colors.purple.shade50 : Colors.teal.shade50,
                                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                                  border: Border.all(
                                                    color: isConsultation ? Colors.purple.shade300 : Colors.teal.shade300,
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.verified_user_rounded,
                                                      size: 10,
                                                      color: isConsultation ? Colors.purple.shade700 : Colors.teal.shade700,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      isConsultation ? 'Tim LKSDM' : 'Otomatis dari Profil',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: isConsultation ? Colors.purple.shade800 : Colors.teal.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            selectedLksdm.name,
                                            style: AppTypography.caption.copyWith(color: AppColors.slate700),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (currentUser?.satuanKerja != null && currentUser!.satuanKerja!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Unit Kerja: ${currentUser!.satuanKerja}',
                                              style: AppTypography.caption.copyWith(color: AppColors.slate500),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Jika Konsultasi LKSDM -> Tampilkan Dropdown Pemilihan Tim Pusat
                              if (isConsultation) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  '2. Tim Pusat yang Dituju *',
                                  style: AppTypography.labelMedium,
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedPusatTeam,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.slate900),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      borderSide: const BorderSide(color: Colors.purple, width: 1.5),
                                    ),
                                  ),
                                  items: TusiCatalogData.centralTeams.map((team) {
                                    return DropdownMenuItem<String>(
                                      value: team,
                                      child: Text(
                                        team,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedPusatTeam = val);
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: Colors.purple.shade200, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_outlined, size: 14, color: Colors.purple.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Tiket ini bersifat privat internal: hanya Anda dan Staf/Ketua $selectedPusatTeam yang dapat berbalas pesan.',
                                          style: TextStyle(fontSize: 10.5, color: Colors.purple.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: AppColors.border, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: AppColors.slate500),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Pertanyaan Anda akan otomatis ditujukan ke Staf Admin dan Ketua Tim ${selectedLksdm.shortName}.',
                                          style: AppTypography.caption.copyWith(color: AppColors.slate600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Judul Input
                              CustomTextField(
                                controller: titleController,
                                focusNode: titleFocusNode,
                                label: isConsultation ? '3. Topik / Judul Konsultasi' : '2. Judul Pertanyaan',
                                hintText: isConsultation
                                    ? 'Contoh: Permohonan Arahan Penetapan Hukuman Disiplin Pegawai...'
                                    : 'Contoh: Prosedur Uji Kompetensi Kenaikan Jabatan...',
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  questionFocusNode.requestFocus();
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return isConsultation
                                        ? 'Topik konsultasi wajib diisi'
                                        : 'Judul pertanyaan wajib diisi';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Detail Pertanyaan Input
                              CustomTextField(
                                controller: questionController,
                                focusNode: questionFocusNode,
                                label: isConsultation ? '4. Rincian Kendala / Permohonan Arahan' : '3. Uraian Pertanyaan Lengkap',
                                hintText: isConsultation
                                    ? 'Jelaskan kronologi kendala atau regulasi yang memerlukan penegasan dari kantor pusat...'
                                    : 'Jelaskan pertanyaan atau kendala yang Anda hadapi secara rinci...',
                                maxLines: 5,
                                textInputAction: TextInputAction.newline,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return isConsultation
                                        ? 'Rincian kendala konsultasi wajib diisi'
                                        : 'Isi pertanyaan wajib diisi';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Lampiran Berkas Bukti (Opsional)
                              Text(
                                isConsultation ? '5. Lampiran Berkas Dukung (Opsional)' : '4. Lampiran Dokumen Bukti (Opsional)',
                                style: AppTypography.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              AttachmentPickerWidget(
                                onAttachmentChanged: (url, name) {
                                  setState(() {
                                    attachedFileUrl = url;
                                    attachedFileName = name;
                                  });
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
                          text: isConsultation ? 'Kirim Konsultasi ke Tim Pusat' : 'Kirim Pertanyaan',
                          backgroundColor: isConsultation ? AppColors.colorSecondaryStrong : AppColors.colorPrimary,
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
