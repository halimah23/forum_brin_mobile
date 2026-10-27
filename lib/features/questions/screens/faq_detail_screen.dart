import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
import '../widgets/publish_and_standardize_dialog.dart';

class FaqDetailScreen extends StatefulWidget {
  final QuestionModel question;
  final UserModel? currentUser;

  const FaqDetailScreen({
    super.key,
    required this.question,
    this.currentUser,
  });

  @override
  State<FaqDetailScreen> createState() => _FaqDetailScreenState();
}

class _FaqDetailScreenState extends State<FaqDetailScreen> {
  late QuestionModel _question;
  bool _showOriginalText = false;
  bool _showAuditTrail = true;
  bool? _isHelpful;

  @override
  void initState() {
    super.initState();
    _question = widget.question;
  }

  bool get _canEdit =>
      widget.currentUser?.isSuperAdmin == true ||
      widget.currentUser?.role?.toLowerCase() == 'super_admin' ||
      widget.currentUser?.role?.toLowerCase() == 'superadmin';

  Future<void> _handleEdit() async {
    final updated = await PublishAndStandardizeDialog.show(context, _question);
    if (updated != null && mounted) {
      setState(() {
        _question = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembakuan dan rangkuman solusi FAQ berhasil diperbarui!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final officialAnswers = _question.answers
            ?.where((a) => a.isOfficial && !a.isSystemEvent)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail FAQ Resmi', style: AppTypography.heading3),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.colorPrimary),
              tooltip: 'Edit Pembakuan & Solusi FAQ',
              onPressed: _handleEdit,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER BADGES
                _buildHeaderBadges(),

                const SizedBox(height: 16),

                // 2. KARTU PERTANYAAN BAKU PEGAWAI
                _buildStandardizedQuestionCard(),

                const SizedBox(height: 20),

                // 3. KARTU RANGKUMAN SOLUSI RESMI SUPERADMIN (HERO CARD)
                _buildOfficialSolutionHeroCard(),

                const SizedBox(height: 24),

                // 4. TRANSPARANSI JEJAK PENANGANAN STAF (LKSDM, PUSAT, KETUA TIM)
                if (officialAnswers.isNotEmpty) ...[
                  _buildOfficialHandlingTrailSection(officialAnswers),
                  const SizedBox(height: 24),
                ],

                // 5. HELPFUL FEEDBACK WIDGET
                _buildHelpfulFeedbackWidget(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Badge Verifikasi Resmi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, size: 14, color: Color(0xFFD97706)),
              SizedBox(width: 5),
              Text(
                'FAQ RESMI BOSDM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),

        // Badge Tim / Tusi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.colorPrimarySoft,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.colorPrimary.withAlpha(50)),
          ),
          child: Text(
            _question.tugasFungsiNama ?? _question.effectiveTargetTim,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.colorPrimary,
            ),
          ),
        ),

        // Tanggal
        Text(
          _question.createdDateTime != null
              ? '${_question.createdDateTime!.day}/${_question.createdDateTime!.month}/${_question.createdDateTime!.year}'
              : 'Terverifikasi',
          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
        ),
      ],
    );
  }

  Widget _buildStandardizedQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pertanyaan Baku Pegawai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              if (_question.isStandardized)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.colorAccentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text(
                    'Bahasa Baku ASN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorAccentWarm,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Judul Pertanyaan Baku
          Text(
            _question.judul,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 10),

          // Isi Pertanyaan Baku
          Text(
            _question.isi,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate700,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Penanya info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 15, color: AppColors.slate500),
                  SizedBox(width: 5),
                  Text(
                    'Diajukan oleh: Pegawai (Identitas Disamarkan)',
                    style: TextStyle(fontSize: 11.5, color: AppColors.slate500),
                  ),
                ],
              ),
              if (_question.isStandardized)
                InkWell(
                  onTap: () => setState(() => _showOriginalText = !_showOriginalText),
                  child: Row(
                    children: [
                      Text(
                        _showOriginalText ? 'Tutup Teks Asli' : 'Lihat Teks Asli',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.colorAccentWarm,
                        ),
                      ),
                      Icon(
                        _showOriginalText ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.colorAccentWarm,
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Teks asli jika diekspansi
          if (_showOriginalText && _question.isStandardized) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.colorAccentSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.colorAccent.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Versi Asli Sebelum Dibakukan:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
                  ),
                  const SizedBox(height: 4),
                  if (_question.originalJudul != null)
                    Text(
                      'Judul: ${_question.originalJudul}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate800, fontWeight: FontWeight.w600),
                    ),
                  if (_question.originalIsi != null)
                    Text(
                      'Uraian: ${_question.originalIsi}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.35),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfficialSolutionHeroCard() {
    final solutionText = _question.hasSummary
        ? _question.summaryJawaban!
        : _question.effectiveOfficialSummary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16A34A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Solusi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RANGKUMAN SOLUSI RESMI BOSDM',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Dirangkum dan divalidasi tuntas oleh Super Admin BOSDM BRIN',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canEdit)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit, size: 14, color: Color(0xFF166534)),
                    label: const Text(
                      'Ubah',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                    onPressed: _handleEdit,
                  ),
              ],
            ),
          ),

          // Body Teks Solusi
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  solutionText,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: Color(0xFF14532D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF15803D)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solusi ini merupakan panduan prosedur operasional resmi kepegawaian BRIN yang berlaku.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialHandlingTrailSection(List<AnswerModel> answers) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showAuditTrail = !_showAuditTrail),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_rounded, size: 20, color: AppColors.slate700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jejak Penanganan Resmi Staf (${answers.length} Tanggapan)',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                        const Text(
                          'Transparansi proses jawaban staf LKSDM, pusat & ketua tim',
                          style: TextStyle(fontSize: 11, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showAuditTrail ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.slate500,
                  ),
                ],
              ),
            ),
          ),
          if (_showAuditTrail) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: answers.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final a = answers[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRoleBadgeIcon(a),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  a.penjawabRole,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                if (a.createdAt != null)
                                  Text(
                                    _formatTime(a.createdAt!),
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.slate400),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              a.isiJawaban,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.slate700,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadgeIcon(AnswerModel a) {
    Color bg = const Color(0xFFEFF6FF);
    Color ic = const Color(0xFF2563EB);
    IconData iconData = Icons.support_agent_rounded;

    if (a.isKetuaTim) {
      bg = const Color(0xFFFEF3C7);
      ic = const Color(0xFFD97706);
      iconData = Icons.military_tech_rounded;
    } else if (a.isAdminPusat) {
      bg = const Color(0xFFF3E8FF);
      ic = const Color(0xFF7E22CE);
      iconData = Icons.domain_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(iconData, size: 18, color: ic),
    );
  }

  Widget _buildHelpfulFeedbackWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Apakah solusi FAQ ini menjawab pertanyaan Anda?',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate800),
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: _isHelpful == true ? const Color(0xFF16A34A) : AppColors.border,
              ),
              backgroundColor: _isHelpful == true ? const Color(0xFFDCFCE7) : null,
            ),
            icon: Icon(
              Icons.thumb_up_rounded,
              size: 14,
              color: _isHelpful == true ? const Color(0xFF16A34A) : AppColors.slate600,
            ),
            label: Text(
              'Ya',
              style: TextStyle(
                fontSize: 12,
                color: _isHelpful == true ? const Color(0xFF16A34A) : AppColors.slate700,
                fontWeight: _isHelpful == true ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onPressed: () {
              setState(() => _isHelpful = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terima kasih atas tanggapan Anda!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: _isHelpful == false ? AppColors.error : AppColors.border,
              ),
              backgroundColor: _isHelpful == false ? const Color(0xFFFEE2E2) : null,
            ),
            icon: Icon(
              Icons.thumb_down_rounded,
              size: 14,
              color: _isHelpful == false ? AppColors.error : AppColors.slate600,
            ),
            label: Text(
              'Tidak',
              style: TextStyle(
                fontSize: 12,
                color: _isHelpful == false ? AppColors.error : AppColors.slate700,
                fontWeight: _isHelpful == false ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onPressed: () {
              setState(() => _isHelpful = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tanggapan dicatat. Anda juga dapat mengajukan tiket konsultasi baru.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
