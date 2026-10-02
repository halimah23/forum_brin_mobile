import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../data/trending_issues_data.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
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
    if (question.status == 'selesai' || question.status == 'dialihkan_ke_pusat') return false;
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
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Text('Eskalasi ke Tim Pusat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem menganalisis konteks pertanyaan dan merekomendasikan Tim Pusat berikut:',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedTeam,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Tim Pusat Tujuan (14 Tim)',
                  filled: true,
                  fillColor: Colors.amber.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedTeam = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Catatan tambahan eskalasi (opsional)',
                  hintText: 'Misal: Membutuhkan verifikasi kebijakan PAK pusat...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, selectedTeam),
              child: const Text('Eskalasikan Sekarang'),
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
        title: const Row(
          children: [
            Icon(Icons.forward_to_inbox, color: Colors.teal),
            SizedBox(width: 8),
            Text('Alihkan ke Admin Tim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setujui pertanyaan publik #${question.ticketNumber ?? question.id} ini untuk dialihkan dan dijawab oleh Admin/Anggota Tim:',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: adminController,
              decoration: InputDecoration(
                labelText: 'Nama / Role Admin Penanggung Jawab',
                hintText: 'Misal: Admin $teamName',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (adminController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, adminController.text.trim());
              }
            },
            child: const Text('Setujui & Alihkan'),
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
        title: Row(
          children: [
            Icon(
              isPrivat ? Icons.security : Icons.reply_all_outlined,
              color: isPrivat ? const Color(0xFF7B1FA2) : AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Text(
              isPrivat
                  ? 'Jawab Langsung (Privat)'
                  : (user?.isAdminLksdm == true
                      ? 'Tanggapan Staf LKSDM'
                      : (user?.isAdminPusat == true
                          ? 'Tanggapan Admin Pusat'
                          : 'Beri Jawaban Resmi')),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    ? 'Tuliskan tanggapan rahasia langsung dari Ketua $teamName untuk menyelesaikan tiket konsultasi privat #${question.ticketNumber ?? question.id}:'
                    : 'Tuliskan penjelasan dan solusi untuk tiket #${question.ticketNumber ?? question.id}:',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: answerController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: isPrivat
                      ? 'Tuliskan arahan dan solusi personal bagi pegawai...'
                      : 'Tuliskan penjelasan dan arahan resmi sesuai SOP...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (answerController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, answerController.text.trim());
              }
            },
            child: const Text('Kirim Tanggapan'),
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
        final nextStatus = (question.status == 'dialihkan_ke_pusat' || question.status == 'eskalasi_pusat')
            ? 'dialihkan_ke_pusat'
            : 'ditangani_lksdm';

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
              // BANNER STATUS PRIVASI / KEAMANAN
              if (!question.isPublic)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFFF3E5F5),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 18, color: Color(0xFF7B1FA2)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'KONSULTASI PRIVAT & RAHASIA — Eksklusif ditangani & dijawab langsung oleh Ketua Tim terkait.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.amber.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda berada di thread topik ini. Balasan di bawah akan tetap pada tiket yang sama.',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AskQuestionScreen(token: widget.currentUser?.token ?? ''),
                            ),
                          );
                        },
                        child: const Text('Topik Lain?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // BANNER RUANG DISKUSI TRIPARTIT (3 USER BERSATU)
              if (question.status == 'dialihkan_ke_pusat' || question.status == 'eskalasi_pusat')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFFFF3E0),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 18, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DISKUSI TRIPARTIT AKTIF — Melibatkan Pegawai, Staf Admin LKSDM, dan Staf ${question.targetTimPusat ?? question.targetTim ?? "Tim Pusat"}.',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                        ),
                      ),
                    ],
                  ),
                ),

              // CHAT THREAD LIST
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // KARTU INFORMASI TIKET
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
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
                                      color: question.isPublic ? const Color(0xFFE8F5E9) : const Color(0xFFF3E5F5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: question.isPublic ? const Color(0xFFA5D6A7) : const Color(0xFFCE93D8),
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          question.isPublic ? Icons.public : Icons.lock_outline,
                                          size: 11,
                                          color: question.isPublic ? const Color(0xFF2E7D32) : const Color(0xFF7B1FA2),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          question.isPublic ? 'Publik' : 'Privat',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: question.isPublic ? const Color(0xFF2E7D32) : const Color(0xFF7B1FA2),
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
                          if (!question.isPublic) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 13, color: Color(0xFF7B1FA2)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Pertanyaan ini bersifat privat dan hanya dapat diakses oleh Anda dan Ketua Tim yang dituju.',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF7B1FA2), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text('Topik Tusi: $tusiText', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          if (question.assignedTo != null && question.assignedTo!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Petugas Ditugaskan: ${question.assignedTo}', style: TextStyle(fontSize: 12, color: Colors.teal.shade800, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),

                    // BUBBLE 1: PERTANYAAN UTAMA MEMBER (Kanan)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16, left: 40),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(4),
                          ),
                          border: Border.all(color: const Color(0xFFBBDEFB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person, size: 14, color: Color(0xFF1565C0)),
                                const SizedBox(width: 4),
                                Text(
                                  namaUser,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                ),
                                const SizedBox(width: 8),
                                if (question.createdAt != null)
                                  Text(
                                    question.createdAt!.split('T').first,
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.judul,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.isi,
                              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // DAFTAR PERCAKAPAN LANJUTAN & JAWABAN RESMI
                    ...answers.map((ans) {
                      if (ans.isSystemEvent) {
                        // SYSTEM EVENT BUBBLE (Tengah)
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ans.isiJawaban,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final bool isOfficial = ans.isOfficial;

                      if (isOfficial) {
                        // TANGGAPAN RESMI STAF ADMIN / KETUA TIM (Sisi Kiri)
                        final isLksdm = ans.isAdminLksdm;
                        final isPusat = ans.isAdminPusat;

                        final headerBg = isPusat
                            ? Colors.amber.shade900
                            : (isLksdm ? Colors.teal.shade800 : Colors.purple.shade800);

                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16, right: 40),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                              ),
                              border: Border.all(color: headerBg.withAlpha(120), width: 1.2),
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
                                Row(
                                  children: [
                                    Icon(Icons.verified, size: 16, color: headerBg),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        ans.penjawabNama,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: headerBg),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: headerBg.withAlpha(25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isPusat ? 'TIM PUSAT' : (isLksdm ? 'STAF LKSDM' : 'KETUA TIM'),
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: headerBg),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  ans.penjawabRole,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Text(
                                  ans.isiJawaban,
                                  style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                                ),
                                if (ans.createdAt != null) ...[
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      ans.createdAt!.split('T').first,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      } else {
                        // PERTANYAAN SUSULAN DARI MEMBER (Sisi Kanan)
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16, left: 40),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(4),
                              ),
                              border: Border.all(color: const Color(0xFF90CAF9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline, size: 13, color: Color(0xFF1565C0)),
                                    const SizedBox(width: 4),
                                    Text(
                                      ans.penjawabNama,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                    ),
                                  ],
                                ),
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
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }
                    }),

                    // KARTU KONFIRMASI KEPUASAN PEGAWAI (FEEDBACK LOOP - HANYA UNTUK PEGAWAI)
                    if (isAuthorPegawai && answers.isNotEmpty && question.status != 'selesai') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.help_outline, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Konfirmasi Penyelesaian Pertanyaan',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Apakah solusi dan penjelasan di atas sudah menjawab pertanyaan Anda?',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onPressed: isProcessing ? null : () => _handleConfirmResolution(true),
                                    icon: const Icon(Icons.check_circle, size: 16),
                                    label: const Text('Ya, Sudah Terjawab', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.amber.shade900,
                                      side: BorderSide(color: Colors.amber.shade900),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onPressed: isProcessing ? null : () => _handleConfirmResolution(false),
                                    icon: const Icon(Icons.forward, size: 16),
                                    label: const Text('Belum / Dialihkan ke Pusat', style: TextStyle(fontSize: 10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // KARTU INFO STATUS UNTUK ADMIN/STAF (JIKA BUKAN PEGAWAI PENGAJU)
                    if (!isAuthorPegawai && answers.isNotEmpty && question.status != 'selesai') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC5E1A5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_clock, size: 16, color: Color(0xFF33691E)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Menunggu konfirmasi penyelesaian dari Pegawai. Hanya Pegawai (pemilik pertanyaan) yang dapat mengakhiri tiket ini.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF33691E), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // KARTU TIKET SELESAI
                    if (question.status == 'selesai') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tiket pertanyaan ini telah diakhiri dan dinyatakan Selesai oleh Pegawai.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (answers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_empty, size: 20, color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pertanyaan sedang menunggu disposisi & tanggapan resmi dari Tim $namaTimTerkait.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      // Tombol Approval / Alihkan ke Admin Tim (Hanya untuk Ketua Tim pada tiket Publik yang menunggu disposisi)
                      if (canDelegateToAdmin && (question.status == 'menunggu_disposisi' || question.status == 'menunggu_lksdm')) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade800,
                              side: BorderSide(color: Colors.teal.shade800),
                            ),
                            onPressed: isProcessing ? null : _handleApproveAndDelegateToAdmin,
                            icon: const Icon(Icons.forward_to_inbox, size: 16),
                            label: const Text('Alihkan ke Admin', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Tombol Alihkan ke Admin Pusat (untuk Staf LKSDM jika pertanyaan belum selesai / butuh eskalasi)
                      if (canEscalateToCentral) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber.shade900,
                              side: BorderSide(color: Colors.amber.shade900),
                            ),
                            onPressed: isProcessing ? null : _promptEscalationToCentral,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Alihkan ke Pusat', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Tombol Jawab Tiket
                      if (canAnswerQuestion)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !question.isPublic
                                  ? const Color(0xFF7B1FA2)
                                  : AppColors.primaryRed,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isProcessing ? null : _handleAnswer,
                            icon: Icon(
                              !question.isPublic ? Icons.security : Icons.reply,
                              size: 16,
                            ),
                            label: Text(
                              !question.isPublic
                                  ? 'Jawab Langsung (Ketua Tim)'
                                  : (widget.currentUser?.isAdminLksdm == true
                                      ? 'Tanggapi (LKSDM)'
                                      : (widget.currentUser?.isAdminPusat == true
                                          ? 'Tanggapi (Pusat)'
                                          : 'Kirim Tanggapan')),
                              style: const TextStyle(fontSize: 12),
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
                  child: question.status == 'selesai'
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
                                decoration: InputDecoration(
                                  hintText: isAuthorPegawai
                                      ? 'Tanya lagi untuk topik ini (#${question.ticketNumber ?? question.id})...'
                                      : 'Tulis tanggapan untuk tiket ini...',
                                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFFF2F4F8),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
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
                              ),
                              onPressed: isSendingReply ? null : _sendFollowUpReply,
                              icon: isSendingReply
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send, size: 18),
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
}
