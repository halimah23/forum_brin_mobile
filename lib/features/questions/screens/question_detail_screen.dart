import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
import '../models/ticket_status.dart';
import '../services/question_service.dart';
import '../widgets/csat_rating_card.dart';
import '../widgets/attachment_viewer_helper.dart';
import '../widgets/reopen_ticket_dialog.dart';
import '../widgets/sender_profile_dialog.dart';
import '../widgets/ticket_timeline_tracker.dart';
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
  RealtimeChannel? _realtimeChannel;
  bool isProcessing = false;
  bool isSendingReply = false;
  bool _showOriginalText = false;

  String? _pendingAttachmentUrl;
  String? _pendingAttachmentName;
  int? _pendingAttachmentSize;
  bool _isUploadingAttachment = false;

  Future<void> _pickReplyAttachment() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran berkas melebihi batas maksimal 10 MB.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingAttachment = true);

      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      String? publicUrl;

      try {
        final client = Supabase.instance.client;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final storagePath = 'chat/${question.id ?? 0}_${timestamp}_$safeName';

        if (bytes != null) {
          await client.storage.from('attachments').uploadBinary(
                storagePath,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
          publicUrl = client.storage.from('attachments').getPublicUrl(storagePath);
        } else {
          publicUrl = file.path ?? 'storage://local_chat/${file.name}';
        }
      } catch (uploadErr) {
        debugPrint('Upload chat attachment error: $uploadErr');
        publicUrl = file.path ?? 'storage://local_chat/${file.name}';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Catatan: Berkas disimpan sementara secara lokal karena unggahan Cloud belum siap ($uploadErr).'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _pendingAttachmentUrl = publicUrl ?? file.name;
          _pendingAttachmentName = file.name;
          _pendingAttachmentSize = file.size;
          _isUploadingAttachment = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking reply attachment: $e');
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  bool _checkIsMe(AnswerModel ans) {
    if (ans.isSystemEvent) return false;
    final currentUserId = widget.currentUser?.id;
    final currentUserName = widget.currentUser?.name.trim().toLowerCase() ?? '';

    if (ans.userId != null && currentUserId != null && ans.userId == currentUserId) {
      return true;
    }
    if (currentUserName.isNotEmpty && ans.penjawabNama.trim().toLowerCase() == currentUserName) {
      return true;
    }
    if (isAuthorPegawai && !ans.isOfficial && !ans.isSystemEvent) {
      return true;
    }
    return false;
  }

  Widget _buildBubbleAttachment({
    required String? attachmentUrl,
    required String? attachmentName,
    required bool isMe,
  }) {
    if (attachmentUrl == null || attachmentUrl.isEmpty) return const SizedBox.shrink();

    final isImg = AttachmentViewerHelper.isImageFile(attachmentUrl, attachmentName);
    final displayName = attachmentName != null && attachmentName.isNotEmpty
        ? attachmentName
        : (isImg ? 'Gambar Lampiran' : 'Dokumen Pendukung');

    if (isImg) {
      final isNetwork = attachmentUrl.startsWith('http://') || attachmentUrl.startsWith('https://');
      Widget imageContent;
      if (isNetwork) {
        imageContent = Image.network(
          attachmentUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildAttachmentErrorTile(displayName, Icons.image_not_supported_outlined),
        );
      } else {
        final localFile = File(attachmentUrl);
        if (localFile.existsSync()) {
          imageContent = Image.file(
            localFile,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _buildAttachmentErrorTile(displayName, Icons.image_not_supported_outlined),
          );
        } else {
          imageContent = _buildAttachmentErrorTile(displayName, Icons.cloud_off_rounded);
        }
      }

      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        constraints: const BoxConstraints(maxHeight: 180, maxWidth: 260),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: isMe ? const Color(0xFFC5E1A5) : const Color(0xFFCBD5E1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: () => AttachmentViewerHelper.openAttachment(
              context,
              url: attachmentUrl,
              fileName: displayName,
            ),
            child: imageContent,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => AttachmentViewerHelper.openAttachment(
        context,
        url: attachmentUrl,
        fileName: displayName,
      ),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFC8E6C9) : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: isMe ? const Color(0xFFA5D6A7) : AppColors.slate300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_rounded, size: 20, color: AppColors.primaryRed),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                displayName,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.slate900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.slate600),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentErrorTile(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.slate100,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.slate500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    question = widget.question;
    _setupRealtimeSubscription();
    _loadFreshDetails();
    _scrollToBottom(isInstant: true);
  }

  void _setupRealtimeSubscription() {
    final qId = question.id;
    if (qId == null) return;
    try {
      _realtimeChannel = QuestionService.subscribeToQuestionAnswers(
        questionId: qId,
        onNewAnswer: (record) {
          if (mounted) {
            _loadFreshDetails();
          }
        },
      );
    } catch (e) {
      debugPrint('Realtime channel error in detail screen: $e');
    }
  }

  void _scrollToBottom({bool isInstant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (isInstant) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  Future<void> _loadFreshDetails() async {
    final qId = question.id;
    if (qId == null) return;
    final fresh = await QuestionService.getQuestionDetail(qId);
    if (fresh != null && mounted) {
      setState(() {
        question = fresh;
      });
      _scrollToBottom(isInstant: true);
    }
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      QuestionService.unsubscribeChannel(_realtimeChannel!);
    }
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

  /// Penanda apakah pengguna saat ini adalah penanya / pengaju pertanyaan tiket ini.
  /// Berlaku untuk Pegawai, Staf LKSDM, maupun Ketua LKSDM yang mengajukan pertanyaan.
  bool get isQuestionOwner => question.isCreatedBy(widget.currentUser);

  /// Alias kompatibilitas untuk isQuestionOwner
  bool get isAuthorPegawai => isQuestionOwner;

  /// Penanda apakah role pengguna berhak melihat identitas penuh pegawai & asal LKSDM
  bool get canViewAuthorFullIdentity {
    final user = widget.currentUser;
    if (user == null) return false;
    return user.isAdminLksdm ||
        user.isAdminPusat ||
        user.isKetuaTim ||
        user.isEksekutif ||
        user.isSuperAdmin ||
        user.userRole == UserRole.admin ||
        user.userRole == UserRole.adminLksdm ||
        user.userRole == UserRole.adminPusat ||
        user.userRole == UserRole.ketuaTim ||
        user.userRole == UserRole.eksekutif ||
        user.userRole == UserRole.superAdmin;
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
          content: Text('Terima kasih! Tiket pertanyaan dinyatakan SELESAI. Silakan isi survei kepuasan layanan di bawah ini.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadFreshDetails();

      // Scroll ke bagian bawah agar kartu survei kepuasan langsung terlihat oleh pengaju tiket
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _promptEscalationToCentral() async {
    final centralTeams = [
      {'code': 'ORTALA', 'name': 'Organisasi dan Tata Laksana'},
      {'code': 'RENBANGRIR', 'name': 'Perencanaan dan Pengembangan Karir SDM'},
      {'code': 'MUKESRA', 'name': 'Mutasi Umum dan Kesejahteraan'},
      {'code': 'JF1', 'name': 'Mutasi & Pengelolaan Jabatan Fungsional I'},
      {'code': 'JF2', 'name': 'Mutasi & Pengelolaan Jabatan Fungsional II'},
      {'code': 'JF3', 'name': 'Mutasi & Pengelolaan Jabatan Fungsional III'},
      {'code': 'RENBANGKOM', 'name': 'Perencanaan & Pengembangan Kompetensi SDM'},
      {'code': 'PENKOM', 'name': 'Penilaian Kompetensi'},
      {'code': 'MANKIN', 'name': 'Manajemen Kinerja dan Penghargaan ASN'},
      {'code': 'BINDIS', 'name': 'Pembinaan dan Penegakan Disiplin ASN'},
      {'code': 'PDIS', 'name': 'Pengelolaan Data dan Informasi SDM'},
      {'code': 'MPR', 'name': 'Sekretariat Majelis Profesor Riset'},
      {'code': 'RB', 'name': 'Sekretariat Reformasi Birokrasi'},
      {'code': 'PKSPU', 'name': 'Program Pembinaan Karir SDM & Penugasan Ulang'},
    ];

    String selectedTeamCode = centralTeams.first['code']!;
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
                initialValue: selectedTeamCode,
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
                items: centralTeams
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['code'],
                        child: Text(
                          '${t['code']} - ${t['name']}',
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedTeamCode = val);
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
              onPressed: () => Navigator.pop(ctx, selectedTeamCode),
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
          penjawabNama: 'Sistem',
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
        _loadFreshDetails();
      }
    }
  }

  bool get canDelegateToAdmin {
    final user = widget.currentUser;
    if (user == null) return false;
    if (!isMatchingTeam) return false;
    // Hanya Ketua Tim & Super Admin yang bisa mendelegasikan tiket ke Admin Tim
    return user.userRole == UserRole.superAdmin || user.userRole == UserRole.ketuaTim;
  }

  void _sendFollowUpReply() async {
    if (widget.currentUser?.isEksekutif == true) return;
    final text = _replyController.text.trim();
    final hasAttachment = _pendingAttachmentUrl != null && _pendingAttachmentUrl!.isNotEmpty;
    if (text.isEmpty && !hasAttachment) return;

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
    } else if (user?.userRole == UserRole.superAdmin) {
      senderRoleType = 'super_admin';
      roleBadgeName = 'Super Admin';
    } else {
      senderRoleType = 'pegawai';
      roleBadgeName = 'Pegawai';
    }

    final attachmentUrlToSend = _pendingAttachmentUrl;
    final attachmentNameToSend = _pendingAttachmentName;
    final messageBody = text.isNotEmpty ? text : (attachmentNameToSend ?? 'Lampiran Berkas');

    final success = await QuestionService.sendFollowUpMessage(
      questionId: question.id ?? 0,
      isiPesan: messageBody,
      pengirimNama: userName,
      pengirimRole: roleBadgeName,
      senderRoleType: senderRoleType,
      attachmentUrl: attachmentUrlToSend,
      attachmentName: attachmentNameToSend,
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
          isiJawaban: messageBody,
          isiPesan: messageBody,
          attachmentUrl: attachmentUrlToSend,
          attachmentName: attachmentNameToSend,
          senderPhotoUrl: user?.photoUrl,
          createdAt: DateTime.now().toIso8601String(),
        );

        final updatedAnswers = List<AnswerModel>.from(question.answers ?? [])..add(newAnswer);
        final nextStatus = (senderRoleType != 'pegawai')
            ? (question.isEscalated ? 'dialihkan_ke_pusat' : 'ditangani_lksdm')
            : question.status;

        setState(() {
          _pendingAttachmentUrl = null;
          _pendingAttachmentName = null;
          _pendingAttachmentSize = null;
          question = question.copyWith(
            status: nextStatus,
            answers: updatedAnswers,
          );
          isSendingReply = false;
        });

        // Auto-scroll ke chat paling baru
        _scrollToBottom(isInstant: false);

        _loadFreshDetails();
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
        _loadFreshDetails();
      }
    }
  }

  Future<void> _handleReopenTicket() async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ReopenTicketDialog.show(
      context,
      question: question,
      superAdminName: widget.currentUser?.name ?? 'Super Admin',
    );

    if (!mounted) return;

    if (success == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tiket berhasil dibuka kembali dan dialihkan penanganannya.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _loadFreshDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String namaTimTerkait = question.targetTim ??
        ((question.tugasFungsi != null && question.tugasFungsi!.isNotEmpty)
            ? question.tugasFungsi!.first.teamName ?? 'Tim Layanan BOSDM'
            : 'Tim Layanan BOSDM');

    final String tusiText = question.tugasFungsiNama ??
        ((question.tugasFungsi != null && question.tugasFungsi!.isNotEmpty)
            ? question.tugasFungsi!.first.fullDisplayName
            : 'Layanan Kepegawaian');

    final answers = question.answers ?? [];

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, true),
          ),
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
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.currentUser?.userRole == UserRole.superAdmin || widget.currentUser?.isSuperAdmin == true) ...[
            IconButton(
              tooltip: question.isPinned ? 'Lepas Pin / Prioritas Tiket' : 'Sematkan / Pin Tiket Prioritas',
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
                            ? 'Tiket berhasil di-Pin sebagai tiket prioritas.'
                            : 'Status Pin tiket dicabut.',
                      ),
                      backgroundColor: newStatus ? Colors.amber.shade900 : Colors.grey.shade800,
                    ),
                  );
                }
              },
            ),
            if (question.isClosed) ...[
              IconButton(
                tooltip: 'Buka Kembali Tiket Selesai',
                icon: const Icon(Icons.replay_rounded, color: Colors.amber),
                onPressed: _handleReopenTicket,
              ),
            ],
          ],
          if (widget.currentUser?.isSuperAdmin != true && widget.currentUser?.isEksekutif != true)
            IconButton(
              tooltip: 'Buat Tiket Baru (Topik Lain)',
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AskQuestionScreen(
                      token: widget.currentUser?.token ?? '',
                      user: widget.currentUser,
                    ),
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
                child: RefreshIndicator(
                  onRefresh: _loadFreshDetails,
                  color: AppColors.primaryRed,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. TIKET TIMELINE TRACKER & SLA
                      TicketTimelineTracker(question: question),
                      const SizedBox(height: 14),

                      // 2. KARTU PEMBUKA TOPIK PERTANYAAN
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
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      question.ticketNumber ?? '#TIKET',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryRed),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StatusBadge(status: question.status, useShortLabel: true),
                                    if (question.isMandiriLksdm) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                          border: Border.all(color: Colors.purple.shade300, width: 0.8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.badge_outlined, size: 10, color: Colors.purple.shade700),
                                            const SizedBox(width: 3),
                                            Text(
                                              'KONSULTASI LKSDM',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primaryRed,
                                  child: Text(
                                    question.getAuthorInitial(widget.currentUser),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question.getAuthorDisplayName(widget.currentUser),
                                        style: AppTypography.labelMedium,
                                      ),
                                      if (question.isAnonymized && canViewAuthorFullIdentity && question.user?.name != null)
                                        Text(
                                          'Identitas Asli: ${question.user!.name}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.slate500),
                                        ),
                                    ],
                                  ),
                                ),
                                if (question.createdAt != null)
                                  Text(
                                    question.createdAt!.split('T').first,
                                    style: AppTypography.caption,
                                  ),
                              ],
                            ),
                            if (canViewAuthorFullIdentity) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person_rounded, size: 14, color: AppColors.slate700),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Pegawai Pengaju: ${question.officialAuthorName}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.slate800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_city_rounded, size: 14, color: AppColors.slate700),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Asal LKSDM: ${question.authorAsalLksdm}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (question.user?.unit != null && question.user!.unit!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.business_outlined, size: 14, color: AppColors.slate500),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Unit Kerja: ${question.user!.unit}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.slate600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            if (question.isStandardized) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF512DA8).withAlpha(15),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: const Color(0xFF512DA8).withAlpha(40)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_fix_high_rounded, size: 14, color: Color(0xFF512DA8)),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        'Telah Dibakukan oleh Superadmin',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF512DA8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => setState(() => _showOriginalText = !_showOriginalText),
                                      child: Text(
                                        _showOriginalText ? 'Tutup Teks Asli' : 'Lihat Teks Asli',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF512DA8),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_showOriginalText) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate100,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: AppColors.slate300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Versi Asli Pegawai Sebelum Dibakukan:',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.slate700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Judul: ${question.originalJudul ?? question.judul}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.slate800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Isi: ${question.originalIsi ?? question.isi}',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.slate700, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],

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
                                  if (question.assignedTo != null && question.assignedTo!.isNotEmpty) ...[
                                    if (tusiText.isNotEmpty) const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Petugas: ${question.assignedTo}',
                                        style: AppTypography.caption.copyWith(color: AppColors.slate700, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // BUBBLE PERTAMA: PERTANYAAN AWAL KONSULTASI PEGAWAI (WhatsApp Style)
                      Builder(builder: (context) {
                        final bool isAuthorMe = isAuthorPegawai;
                        final authorDisplayName = question.getAuthorDisplayName(widget.currentUser);

                        if (isAuthorMe) {
                          // Dari sisi Pegawai aktif (Sisi Kanan - WhatsApp Light Green Bubble)
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12, left: 40),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          authorDisplayName,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC8E6C9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'KONSULTASI AWAL',
                                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    question.judul,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.isi,
                                    style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                                  ),
                                  if (question.attachmentUrl != null && question.attachmentUrl!.isNotEmpty)
                                    _buildBubbleAttachment(
                                      attachmentUrl: question.attachmentUrl,
                                      attachmentName: question.attachmentName ?? 'Berkas Pendukung',
                                      isMe: true,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (question.createdAt != null)
                                        Text(
                                          question.createdAt!.split('T').first,
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
                        } else {
                          // Dari sisi Admin / Staf / Pusat / Ketua Tim (Sisi Kiri - White Card Bubble)
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
                                  InkWell(
                                    onTap: () {
                                      SenderProfileDialog.show(
                                        context: context,
                                        senderName: question.officialAuthorName,
                                        senderRole: 'PEGAWAI BRIN',
                                        userId: question.userId,
                                        userEmail: question.user?.email,
                                        photoUrl: question.user?.photoUrl,
                                        jabatan: question.user?.jabatan,
                                        unit: question.user?.unit,
                                        lksdm: question.authorAsalLksdm,
                                        isAnonymized: question.isAnonymized && !canViewAuthorFullIdentity,
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person_rounded, size: 14, color: Color(0xFF2E7D32)),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            canViewAuthorFullIdentity
                                                ? '$authorDisplayName (Asal: ${question.authorAsalLksdm})'
                                                : authorDisplayName,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                            border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                                          ),
                                          child: const Text(
                                            'PEGAWAI',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Divider(height: 1, color: AppColors.border),
                                  const SizedBox(height: 6),
                                  Text(
                                    question.judul,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.isi,
                                    style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                                  ),
                                  if (question.attachmentUrl != null && question.attachmentUrl!.isNotEmpty)
                                    _buildBubbleAttachment(
                                      attachmentUrl: question.attachmentUrl,
                                      attachmentName: question.attachmentName ?? 'Berkas Pendukung',
                                      isMe: false,
                                    ),
                                  if (question.createdAt != null) ...[
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        question.createdAt!.split('T').first,
                                        style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }
                      }),

                      // DAFTAR PERCAKAPAN LANJUTAN & JAWABAN RESMI
                      ...answers.map((ans) {
                        if (ans.isSystemEvent) {
                          if (ans.isResolutionEvent) {
                            // SYSTEM EVENT KHUSUS: KONFIRMASI TERJAWAB (Tengah - Amber / Emas)
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD97706).withAlpha(20),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFDE68A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFFB45309)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ans.isiJawaban,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // SYSTEM EVENT STANDAR (Tengah - Abu Slate)
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

                        final bool isMe = _checkIsMe(ans);

                        if (isMe) {
                          // BUBBLE PENGGUNA AKTIF (Sisi Kanan - WhatsApp Light Green Bubble)
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
                                  if (ans.attachmentUrl != null && ans.attachmentUrl!.isNotEmpty)
                                    _buildBubbleAttachment(
                                      attachmentUrl: ans.attachmentUrl,
                                      attachmentName: ans.attachmentName ?? 'Lampiran',
                                      isMe: true,
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
                        } else {
                          // BUBBLE LAWAN BICARA (Sisi Kiri - White Card Bubble dengan Header Berwarna & Tappable Profile)
                          final isLksdm = ans.isAdminLksdm;
                          final isPusat = ans.isAdminPusat;
                          final isKetua = ans.isKetuaTim;

                          final headerBg = isPusat
                              ? Colors.amber.shade900
                              : (isLksdm
                                  ? Colors.teal.shade800
                                  : (isKetua ? Colors.purple.shade800 : const Color(0xFF2E7D32)));

                          final roleBadgeLabel = isPusat
                              ? 'TIM PUSAT'
                              : (isLksdm
                                  ? 'STAF LKSDM'
                                  : (isKetua ? 'KETUA TIM' : 'PEGAWAI'));

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
                                  InkWell(
                                    onTap: () {
                                      SenderProfileDialog.show(
                                        context: context,
                                        senderName: ans.penjawabNama,
                                        senderRole: ans.penjawabRole,
                                        userId: ans.userId,
                                        userEmail: ans.senderEmail,
                                        photoUrl: ans.senderPhotoUrl,
                                        jabatan: ans.senderJabatan,
                                        unit: ans.senderUnit,
                                        lksdm: ans.senderLksdm,
                                        isAnonymized: false,
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_rounded, size: 14, color: headerBg),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            ans.penjawabNama,
                                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: headerBg),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.slate100,
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                            border: Border.all(color: AppColors.slate300, width: 1),
                                          ),
                                          child: Text(
                                            roleBadgeLabel,
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate800),
                                          ),
                                        ),
                                      ],
                                    ),
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
                                  if (ans.attachmentUrl != null && ans.attachmentUrl!.isNotEmpty)
                                    _buildBubbleAttachment(
                                      attachmentUrl: ans.attachmentUrl,
                                      attachmentName: ans.attachmentName ?? 'Lampiran',
                                      isMe: false,
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
                        }
                      }),

                      // KARTU KONFIRMASI KEPUASAN (FEEDBACK LOOP - HANYA UNTUK PENANYA TIKET)
                      if (isQuestionOwner && answers.isNotEmpty && !question.isClosed) ...[
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

                      // EVENT PILL INFO STATUS (JIKA BUKAN PENANYA TIKET)
                      if (!isQuestionOwner && answers.isNotEmpty && !question.isClosed) ...[
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
                              const Icon(Icons.lock_clock_outlined, size: 13, color: AppColors.slate700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  question.isMandiriLksdm
                                      ? 'Menunggu konfirmasi penyelesaian dari Tim LKSDM (penanya).'
                                      : 'Menunggu konfirmasi penyelesaian dari penanya tiket.',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.slate800),
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
                        // Survei Kepuasan Layanan (CSAT):
                        // Cukup tampil pada user yang mengajukan pertanyaan (pemilik tiket, baik Pegawai maupun Staf/Ketua LKSDM).
                        // Jika bukan pengaju tiket (admin/penjawab/eksekutif), kartu survei hanya tampil sebagai laporan evaluasi jika sudah dinilai oleh pengaju.
                        if (isQuestionOwner) ...[
                          const SizedBox(height: 14),
                          CsatRatingCard(
                            question: question,
                            onRatingSubmitted: _loadFreshDetails,
                          ),
                        ] else if (question.rating != null && question.rating! > 0 && canViewAuthorFullIdentity) ...[
                          const SizedBox(height: 14),
                          CsatRatingCard(
                            question: question,
                            isReadOnly: true,
                          ),
                        ],
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
              ),

              // TOOLBAR AKSI DISPOSISI & ESKALASI (HANYA DITAMPILKAN JIKA ADA AKSI YANG TERSEDIA)
              if ((canDelegateToAdmin && question.ticketStatus == TicketStatus.open) || canEscalateToCentral)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        if (canEscalateToCentral) const SizedBox(width: 8),
                      ],
                      // Tombol Alihkan ke Admin Pusat
                      if (canEscalateToCentral)
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
                    ],
                  ),
                ),

              // INPUT BAR PERTANYAAN LANJUTAN MEMBER / MONITORING BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: SafeArea(
                  child: widget.currentUser?.isEksekutif == true
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF283593)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mode Monitoring: Hak akses Eksekutif bersifat hanya-lihat (Read-Only).',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : (question.isClosed
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Tiket telah selesai diakhiri oleh Pegawai.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (widget.currentUser?.userRole == UserRole.superAdmin || widget.currentUser?.isSuperAdmin == true) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber.shade900,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                      ),
                                      icon: const Icon(Icons.replay_rounded, size: 14),
                                      label: const Text('Buka Kembali', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: _handleReopenTicket,
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_pendingAttachmentName != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(color: AppColors.slate300),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primaryRed),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$_pendingAttachmentName (${_formatFileSize(_pendingAttachmentSize ?? 0)})',
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.slate800),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _pendingAttachmentUrl = null;
                                              _pendingAttachmentName = null;
                                              _pendingAttachmentSize = null;
                                            });
                                          },
                                          child: const Icon(Icons.close, size: 16, color: AppColors.slate600),
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: _isUploadingAttachment
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 2),
                                            )
                                          : const Icon(Icons.attach_file_rounded, color: AppColors.slate600, size: 22),
                                      onPressed: (_isUploadingAttachment || isSendingReply) ? null : _pickReplyAttachment,
                                      tooltip: 'Lampirkan Berkas / Gambar (Maks 10 MB)',
                                    ),
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
                                      onPressed: (isSendingReply || _isUploadingAttachment) ? null : _sendFollowUpReply,
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
                              ],
                            )),
                ),
              ),
            ],
          ),
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
