import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../data/trending_issues_data.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
import '../models/ticket_status.dart';
import '../services/question_service.dart';
import 'ask_question_screen.dart';

class QuestionDetailScreen extends StatefulWidget {
  final QuestionModel question;
  final UserModel? currentUser;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.currentUser,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  late QuestionModel question;
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isProcessing = false;
  bool isSendingReply = false;

  @override
  void initState() {
    super.initState();
    question = widget.question;
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get isMatchingTeam {
    final user = widget.currentUser;
    if (user == null) return false;
    if (user.userRole == UserRole.superAdmin) return true;
    if (user.isAdminLksdm) return true;
    if (user.tim == null || user.tim!.isEmpty) return true;
    final target = question.targetTim?.toLowerCase() ?? '';
    final targetPusat = question.targetTimPusat?.toLowerCase() ?? '';
    final userTim = user.tim!.toLowerCase();
    return target.contains(userTim) || userTim.contains(target) || targetPusat.contains(userTim);
  }

  bool get canAnswerQuestion {
    final user = widget.currentUser;
    if (user == null) return false;
    if (user.userRole == UserRole.eksekutif) return false;
    if (user.userRole == UserRole.superAdmin) return true;
    return user.userRole == UserRole.admin ||
        user.isAdminLksdm ||
        user.isAdminPusat ||
        user.userRole == UserRole.ketuaTim;
  }

  bool get canEscalateToCentral {
    final user = widget.currentUser;
    if (user == null) return false;
    if (question.isClosed || question.ticketStatus == TicketStatus.escalated || question.ticketStatus == TicketStatus.inProgressCenter) return false;
    return user.isAdminLksdm || user.userRole == UserRole.superAdmin || user.userRole == UserRole.ketuaTim;
  }

  /// Hanya Pegawai (pemilik pertanyaan) yang berhak mengakhiri dan menyelesaikan tiket
  bool get isAuthorPegawai {
    final user = widget.currentUser;
    if (user == null) return false;
    if (question.user?.id != null && user.id == question.user!.id) return true;
    return user.isPegawai;
  }

  void _handleConfirmResolution(bool isResolved) async {
    if (!isResolved) {
      // Pemicu eskalasi cerdas ke 1 dari 14 Tim Pusat
      _promptEscalationToCentral();
      return;
    }

    setState(() => isProcessing = true);
    final success = await QuestionService.confirmAnswerResolution(
      questionId: question.id ?? 0,
      isResolved: true,
    );

    if (mounted) {
      setState(() {
        isProcessing = false;
        if (success) {
          question = question.copyWith(status: 'selesai');
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Tiket pertanyaan dinyatakan SELESAI.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _promptEscalationToCentral() async {
    final suggestedTeam = TrendingIssuesData.suggestCentralTeam(question.judul, question.isi);
    String selectedTeam = suggestedTeam;

    final teams = [
      'Tim Kelompok Jabatan Fungsional',
      'Tim Mutasi & Kepangkatan',
      'Tim Penggajian & Tunjangan',
      'Tim Kesejahteraan & Kinerja Pegawai',
      'Tim Pengembangan Kapasitas SDM',
      'Tim Pensiun & Pemberhentian',
      'Tim Penegakan Disiplin & Etika',
      'Tim Layanan SDM Pusat',
    ];

    if (!teams.contains(suggestedTeam)) {
      teams.insert(0, suggestedTeam);
    }

    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: AppColors.slate800,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Eskalasi ke Tim Pusat', style: AppTypography.heading3),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Tim Pusat tujuan eskalasi tiket:',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedTeam,
                isExpanded: true,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Tim Pusat Tujuan',
                  labelStyle: AppTypography.caption,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    borderSide: const BorderSide(color: AppColors.slate800, width: 1.5),
                  ),
                ),
                items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.bodySmall))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedTeam = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Catatan tambahan eskalasi (opsional)',
                  labelStyle: AppTypography.caption,
                  hintText: 'Misal: Membutuhkan verifikasi kebijakan PAK pusat...',
                  hintStyle: AppTypography.caption,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    borderSide: const BorderSide(color: AppColors.slate800, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.slate900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onPressed: () => Navigator.pop(ctx, selectedTeam),
              icon: const Icon(Icons.alt_route_rounded, size: 16),
              label: const Text('Eskalasikan Sekarang'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => isProcessing = true);
      final success = await QuestionService.escalateToCentralTeam(
        questionId: question.id ?? 0,
        centralTeamName: result,
        escalatedBy: widget.currentUser?.name ?? 'Staf Admin LKSDM',
        reason: reasonController.text.trim(),
      );

      if (mounted) {
        final newSystemAnswer = AnswerModel(
          questionId: question.id ?? 0,
          penjawabNama: 'Sistem Forum',
          penjawabRole: 'Sistem',
          senderRoleType: 'system_event',
          isiJawaban: 'Pertanyaan telah dieskalasikan ke $result. Ruang percakapan bertransformasi menjadi Tripartit (Pegawai + Staf LKSDM + Tim Pusat).',
          createdAt: DateTime.now().toIso8601String(),
        );

        final updatedAnswers = List<AnswerModel>.from(question.answers ?? [])..add(newSystemAnswer);

        setState(() {
          isProcessing = false;
          if (success) {
            question = question.copyWith(
              status: 'eskalasi_pusat',
              escalatedToTeam: result,
              answers: updatedAnswers,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pertanyaan berhasil dieskalasikan ke $result.'),
            backgroundColor: Colors.amber.shade900,
          ),
        );
      }
    }
  }

  bool get canDelegateToAdmin {
    final user = widget.currentUser;
    if (user == null) return false;
    if (!isMatchingTeam) return false;
    // Hanya Ketua Tim & Super Admin yang bisa mendelegasikan tiket Publik ke Admin Tim
    return question.isPublic &&
        (user.userRole == UserRole.superAdmin || user.userRole == UserRole.ketuaTim);
  }

  void _sendFollowUpReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => isSendingReply = true);
    final user = widget.currentUser;
    final userName = user?.name ?? 'Pegawai';
    final String senderRoleType;
    final String roleBadgeName;
    if (user?.isAdminPusat == true) {
      senderRoleType = 'admin_pusat';
      roleBadgeName = 'Staf Admin Pusat';
    } else if (user?.isAdminLksdm == true) {
      senderRoleType = 'admin_lksdm';
      roleBadgeName = 'Staf Admin LKSDM';
    } else if (user?.userRole == UserRole.ketuaTim) {
      senderRoleType = 'ketua_tim';
      roleBadgeName = 'Ketua Tim';
    } else {
      senderRoleType = 'pegawai';
      roleBadgeName = 'Pegawai';
    }

    final success = await QuestionService.sendFollowUpMessage(
      questionId: question.id ?? 0,
      isiPesan: text,
      pengirimNama: userName,
      pengirimRole: roleBadgeName,
      senderRoleType: senderRoleType,
    );

    if (mounted) {
      if (success) {
        _replyController.clear();
        final newAnswer = AnswerModel(
          questionId: question.id ?? 0,
          penjawabNama: userName,
          penjawabRole: roleBadgeName,
          senderName: userName,
          senderRole: roleBadgeName,
          senderRoleType: senderRoleType,
          isiJawaban: text,
          isiPesan: text,
          createdAt: DateTime.now().toIso8601String(),
        );

        final updatedAnswers = List<AnswerModel>.from(question.answers ?? [])..add(newAnswer);
        setState(() {
          question = question.copyWith(
            answers: updatedAnswers,
          );
          isSendingReply = false;
        });

        // Scroll ke bawah
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pertanyaan lanjutan berhasil dikirimkan ke tim terkait.'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        setState(() => isSendingReply = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim pesan. Silakan periksa koneksi Anda.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleApproveAndDelegateToAdmin() async {
    final teamName = question.targetTim ?? widget.currentUser?.tim ?? 'Tim BOSDM';
    final adminController = TextEditingController(text: 'Admin $teamName');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.forward_to_inbox_rounded,
                color: AppColors.slate800,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Disposisi ke Admin Tim', style: AppTypography.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tugaskan pertanyaan #${question.ticketNumber ?? question.id} ini kepada Staf Admin Tim:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: adminController,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Nama / Role Admin Penanggung Jawab',
                labelStyle: AppTypography.caption,
                hintText: 'Misal: Admin $teamName',
                hintStyle: AppTypography.caption,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  borderSide: const BorderSide(color: AppColors.slate800, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.slate900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () {
              if (adminController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, adminController.text.trim());
              }
            },
            icon: const Icon(Icons.forward_to_inbox_rounded, size: 16),
            label: const Text('Disposisikan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => isProcessing = true);
      final success = await QuestionService.approveAndDelegateToAdmin(
        questionId: question.id ?? 0,
        targetTeam: teamName,
        adminName: result,
      );

      if (mounted) {
        setState(() {
          isProcessing = false;
          if (success) {
            question = question.copyWith(
              status: 'sedang_diproses',
              assignedTo: result,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pertanyaan berhasil disetujui & dialihkan kepada $result.'),
            backgroundColor: Colors.teal.shade800,
          ),
        );
      }
    }
  }

  void _handleAnswer() async {
    final answerController = TextEditingController();
    final user = widget.currentUser;
    final isPrivat = !question.isPublic;
    final String roleName;
    final String senderRoleType;
    if (user?.isAdminPusat == true) {
      roleName = 'Staf Admin Pusat';
      senderRoleType = 'admin_pusat';
    } else if (user?.isAdminLksdm == true) {
      roleName = 'Staf Admin LKSDM';
      senderRoleType = 'admin_lksdm';
    } else if (isPrivat) {
      roleName = 'Ketua Tim (Penanganan Langsung)';
      senderRoleType = 'ketua_tim';
    } else if (user?.userRole == UserRole.ketuaTim) {
      roleName = 'Ketua Tim';
      senderRoleType = 'ketua_tim';
    } else {
      roleName = 'Admin Layanan';
      senderRoleType = 'admin';
    }
    final teamName = user?.tim ?? question.targetTim ?? 'Tim BOSDM';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.slate800,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isPrivat
                  ? 'Tanggapan Konsultasi Privat'
                  : (user?.isAdminLksdm == true
                      ? 'Tanggapan Staf LKSDM'
                      : (user?.isAdminPusat == true
                          ? 'Tanggapan Admin Pusat'
                          : 'Beri Jawaban Resmi')),
              style: AppTypography.heading3,
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPrivat
                    ? 'Tuliskan tanggapan langsung dari Ketua $teamName untuk tiket privat #${question.ticketNumber ?? question.id}:'
                    : 'Tuliskan penjelasan dan solusi untuk tiket #${question.ticketNumber ?? question.id}:',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: answerController,
                maxLines: 5,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: isPrivat
                      ? 'Tuliskan arahan dan solusi personal bagi pegawai...'
                      : 'Tuliskan penjelasan dan arahan resmi sesuai SOP...',
                  hintStyle: AppTypography.caption,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(12),
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
                    borderSide: const BorderSide(color: AppColors.slate800, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () {
              if (answerController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, answerController.text.trim());
              }
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Kirim Tanggapan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => isProcessing = true);
      final success = await QuestionService.answerAndResolveTicket(
        questionId: question.id ?? 0,
        penjawabNama: user?.name ?? teamName,
        penjawabRole: '$roleName ($teamName)',
        senderRoleType: senderRoleType,
        isiJawaban: result,
        currentStatus: question.status,
      );

      if (mounted) {
        final newAnswer = AnswerModel(
          questionId: question.id ?? 0,
          penjawabNama: user?.name ?? teamName,
          penjawabRole: '$roleName ($teamName)',
          senderName: user?.name ?? teamName,
          senderRole: '$roleName ($teamName)',
          senderRoleType: senderRoleType,
          isiJawaban: result,
          isiPesan: result,
          createdAt: DateTime.now().toIso8601String(),
        );

        final updatedAnswers = List<AnswerModel>.from(question.answers ?? [])..add(newAnswer);
        final nextStatus = (question.ticketStatus == TicketStatus.escalated || question.ticketStatus == TicketStatus.inProgressCenter)
            ? 'ESCALATED'
            : 'IN_PROGRESS';

        setState(() {
          isProcessing = false;
          if (success) {
            question = question.copyWith(
              status: nextStatus,
              answers: updatedAnswers,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggapan berhasil dikirim ke Pegawai. Menunggu konfirmasi penyelesaian dari Pegawai.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String namaUser = question.user?.name ?? 'Pegawai BRIN';
    final String namaTimTerkait = question.targetTim ??
        ((question.tugasFungsi != null && question.tugasFungsi!.isNotEmpty)
            ? question.tugasFungsi!.first.teamName ?? 'Tim Layanan BOSDM'
            : 'Tim Layanan BOSDM');

    final String tusiText = question.tugasFungsiNama ??
        ((question.tugasFungsi != null && question.tugasFungsi!.isNotEmpty)
            ? question.tugasFungsi!.first.fullDisplayName
            : 'Layanan Kepegawaian');

    final answers = question.answers ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.ticketNumber != null ? 'Tiket ${question.ticketNumber}' : 'Detail Pertanyaan',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            Text(
              namaTimTerkait,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          if (widget.currentUser?.userRole == UserRole.superAdmin || widget.currentUser?.isSuperAdmin == true)
            IconButton(
              tooltip: question.isPinned ? 'Lepas Pin / Up Tiket' : 'Up / Pin Pertanyaan Banyak Ditanyakan',
              icon: Icon(
                question.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: question.isPinned ? Colors.amber : Colors.white,
              ),
              onPressed: () async {
                final newStatus = !question.isPinned;
                final success = await QuestionService.togglePinQuestion(
                  questionId: question.id ?? 0,
                  isPinned: newStatus,
                );
                if (context.mounted && success) {
                  setState(() {
                    question = question.copyWith(isPinned: newStatus);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newStatus
                            ? 'Pertanyaan berhasil di-Up / Dipin sebagai isu utama yang sering ditanyakan.'
                            : 'Status Pin / Up pertanyaan dicabut.',
                      ),
                      backgroundColor: newStatus ? Colors.amber.shade900 : Colors.grey.shade800,
                    ),
                  );
                }
              },
            ),
          IconButton(
            tooltip: 'Buat Tiket Baru (Topik Lain)',
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AskQuestionScreen(token: widget.currentUser?.token ?? ''),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // CHAT THREAD LIST
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // KARTU INFORMASI TIKET
                    // KARTU PEMBUKA TOPIK PERTANYAAN
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    question.ticketNumber ?? '#TIKET',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryRed),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate100,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(color: AppColors.slate300, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          question.isPublic ? Icons.public : Icons.lock_outline,
                                          size: 10,
                                          color: AppColors.slate700,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          question.isPublic ? 'Publik' : 'Privat',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.slate700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(status: question.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryRed,
                                child: Text(
                                  namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'P',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  namaUser,
                                  style: AppTypography.labelMedium,
                                ),
                              ),
                              if (question.createdAt != null)
                                Text(
                                  question.createdAt!.split('T').first,
                                  style: AppTypography.caption,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            question.judul,
                            style: AppTypography.heading3.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            question.isi,
                            style: AppTypography.bodySmall.copyWith(fontSize: 13, height: 1.45),
                          ),
                          if (tusiText.isNotEmpty || (question.assignedTo != null && question.assignedTo!.isNotEmpty)) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (tusiText.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      'Topik: $tusiText',
                                      style: AppTypography.caption.copyWith(color: AppColors.slate600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (question.assignedTo != null && question.assignedTo!.isNotEmpty)
                                  Text(
                                    'Petugas: ${question.assignedTo}',
                                    style: AppTypography.caption.copyWith(color: AppColors.slate700, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // DAFTAR PERCAKAPAN LANJUTAN & JAWABAN RESMI
                    ...answers.map((ans) {
                      if (ans.isSystemEvent) {
                        // SYSTEM EVENT BUBBLE (Tengah)
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.slate300, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.slate700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ans.isiJawaban,
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.slate800),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final bool isOfficial = ans.isOfficial;

                      if (isOfficial) {
                        // TANGGAPAN RESMI STAF ADMIN / KETUA TIM (Sisi Kiri - White Card)
                        final isLksdm = ans.isAdminLksdm;
                        final isPusat = ans.isAdminPusat;

                        final headerBg = isPusat
                            ? Colors.amber.shade900
                            : (isLksdm ? Colors.teal.shade800 : Colors.purple.shade800);

                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12, right: 40),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                              ),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.verified, size: 15, color: headerBg),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        ans.penjawabNama,
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: headerBg),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate100,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(color: AppColors.slate300, width: 1),
                                      ),
                                      child: Text(
                                        isPusat ? 'TIM PUSAT' : (isLksdm ? 'STAF LKSDM' : 'KETUA TIM'),
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate800),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  ans.penjawabRole,
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 6),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 6),
                                Text(
                                  ans.isiJawaban,
                                  style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                                ),
                                if (ans.createdAt != null) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      ans.createdAt!.split('T').first,
                                      style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      } else {
                        // PERTANYAAN SUSULAN DARI MEMBER (Sisi Kanan - WhatsApp Light Green Bubble)
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12, left: 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCF8C6),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(4),
                              ),
                              border: Border.all(color: const Color(0xFFC5E1A5), width: 0.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ans.penjawabNama,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ans.isiJawaban,
                                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (ans.createdAt != null)
                                      Text(
                                        ans.createdAt!.split('T').first,
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF558B2F)),
                                      ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.done_all, size: 13, color: Color(0xFF2E7D32)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }),

                    // KARTU KONFIRMASI KEPUASAN PEGAWAI (FEEDBACK LOOP - HANYA UNTUK PEGAWAI)
                    if (isAuthorPegawai && answers.isNotEmpty && !question.isClosed) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.help_outline_rounded, color: AppColors.slate700, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Konfirmasi Penyelesaian',
                                  style: AppTypography.labelMedium.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Apakah solusi dan penjelasan di atas telah menjawab pertanyaan Anda?',
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                    onPressed: isProcessing ? null : () => _handleConfirmResolution(true),
                                    label: const Text('Ya, Sudah Terjawab', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.slate800,
                                      side: const BorderSide(color: AppColors.slate300),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                    onPressed: isProcessing ? null : () => _handleConfirmResolution(false), 
                                    label: const Text('Belum / Butuh Eskalasi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            _buildTimelineStepper(),
                          ],
                        ),
                      ),
                    ],

                    // EVENT PILL INFO STATUS UNTUK ADMIN/STAF (JIKA BUKAN PEGAWAI PENGAJU)
                    if (!isAuthorPegawai && answers.isNotEmpty && !question.isClosed) ...[
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.slate300, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_clock_outlined, size: 13, color: AppColors.slate700),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Menunggu konfirmasi penyelesaian dari Pegawai (pemilik pertanyaan).',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.slate800),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // EVENT PILL TIKET SELESAI
                    if (question.isClosed) ...[
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.slate300, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tiket pertanyaan ini telah diakhiri dan dinyatakan Selesai.',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.slate800),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // EVENT PILL MENUNGGU DISPOSISI (Hanya jika belum selesai dan belum ada jawaban)
                    if (answers.isEmpty && !question.isClosed) ...[
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.slate300, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_top_rounded, size: 13, color: AppColors.slate700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Pertanyaan sedang menunggu disposisi & tanggapan resmi dari Tim $namaTimTerkait.',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.slate800),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // TOOLBAR AKSI KETUA TIM & ADMIN TIM & ADMIN LKSDM
              if (canAnswerQuestion || canDelegateToAdmin || canEscalateToCentral)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // Tombol Approval / Alihkan ke Admin Tim
                      if (canDelegateToAdmin && question.ticketStatus == TicketStatus.open) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.slate800,
                              side: const BorderSide(color: AppColors.slate300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            onPressed: isProcessing ? null : _handleApproveAndDelegateToAdmin,
                            icon: const Icon(Icons.forward_to_inbox_rounded, size: 16),
                            label: const Text('Disposisi Ke Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Tombol Alihkan ke Admin Pusat
                      if (canEscalateToCentral) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.slate800,
                              side: const BorderSide(color: AppColors.slate300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            onPressed: isProcessing ? null : _promptEscalationToCentral,
                            icon: const Icon(Icons.alt_route_rounded, size: 16),
                            label: const Text('Alihkan ke Pusat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Tombol Jawab Tiket
                      if (canAnswerQuestion)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            onPressed: isProcessing ? null : _handleAnswer,
                            icon: const Icon(
                              Icons.reply_rounded,
                              size: 16,
                            ),
                            label: Text(
                              !question.isPublic
                                  ? 'Jawab Langsung'
                                  : (widget.currentUser?.isAdminLksdm == true
                                      ? 'Tanggapi (LKSDM)'
                                      : (widget.currentUser?.isAdminPusat == true
                                          ? 'Tanggapi (Pusat)'
                                          : 'Kirim Tanggapan')),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // INPUT BAR PERTANYAAN LANJUTAN MEMBER (UNTUK TOPIK YANG SAMA)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: SafeArea(
                  child: question.isClosed
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                'Tiket telah selesai diakhiri oleh Pegawai.',
                                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                minLines: 1,
                                maxLines: 3,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendFollowUpReply(),
                                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                                decoration: InputDecoration(
                                  hintText: isAuthorPegawai
                                      ? 'Tulis pertanyaan susulan...'
                                      : 'Tulis tanggapan untuk tiket ini...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(10),
                              ),
                              onPressed: isSendingReply ? null : _sendFollowUpReply,
                              icon: isSendingReply
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStepper() {
    final status = question.ticketStatus;
    const isStep1 = true;
    final isStep2 = status != TicketStatus.open;
    final isStep3 = question.isEscalated;
    final isStep4 = status.isClosed;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audit Trail & Timeline Tiket', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate700)),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepDot(isStep1, 'Dibuat'),
              _stepLine(isStep2),
              _stepDot(isStep2, 'LKSDM'),
              _stepLine(isStep3),
              _stepDot(isStep3, 'Pusat'),
              _stepLine(isStep4),
              _stepDot(isStep4, 'Closed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepDot(bool active, String label) {
    final color = active ? AppColors.primaryRed : AppColors.slate400;
    return Column(
      children: [
        Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: color),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: color)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? AppColors.primaryRed : AppColors.slate300,
        margin: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }
}
