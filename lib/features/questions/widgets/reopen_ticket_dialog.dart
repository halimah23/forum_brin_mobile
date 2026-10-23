import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../data/lksdm_catalog_data.dart';
import '../data/tusi_catalog_data.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';

class ReopenTicketDialog extends StatefulWidget {
  final QuestionModel question;
  final String superAdminName;

  const ReopenTicketDialog({
    super.key,
    required this.question,
    required this.superAdminName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required QuestionModel question,
    required String superAdminName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReopenTicketDialog(
        question: question,
        superAdminName: superAdminName,
      ),
    );
  }

  @override
  State<ReopenTicketDialog> createState() => _ReopenTicketDialogState();
}

class _ReopenTicketDialogState extends State<ReopenTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  late String _targetType; // 'lksdm' atau 'pusat'
  late String _selectedLksdm;
  late String _selectedPusatTeam;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final hadCentralEscalation = widget.question.isEscalated ||
        (widget.question.targetTimPusat != null &&
            widget.question.targetTimPusat!.isNotEmpty);
    _targetType = hadCentralEscalation ? 'pusat' : 'lksdm';

    // Inisialisasi default LKSDM
    final existingLksdm = widget.question.lksdmKawasan;
    final validLksdm = LksdmCatalogData.allLksdm.any(
      (l) => l.shortName == existingLksdm || l.name == existingLksdm,
    );
    _selectedLksdm = validLksdm
        ? (existingLksdm!.startsWith('LKSDM')
            ? existingLksdm
            : LksdmCatalogData.allLksdm
                .firstWhere((l) => l.name == existingLksdm)
                .shortName)
        : LksdmCatalogData.allLksdm.first.shortName;

    // Inisialisasi default Tim Pusat
    final existingPusat = widget.question.targetTimPusat;
    if (existingPusat != null &&
        TusiCatalogData.centralTeams.contains(existingPusat)) {
      _selectedPusatTeam = existingPusat;
    } else {
      _selectedPusatTeam = TusiCatalogData.centralTeams.first;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.question.id == null) return;

    setState(() => _isSubmitting = true);

    final isCentral = _targetType == 'pusat';
    final targetStatus = isCentral ? 'dialihkan_ke_pusat' : 'menunggu_lksdm';

    final success = await QuestionService.reopenTicket(
      questionId: widget.question.id!,
      targetStatus: targetStatus,
      reason: _reasonController.text.trim(),
      superAdminName: widget.superAdminName,
      authorUserId: widget.question.user?.id,
      ticketNumber: widget.question.ticketNumber,
      targetLksdmKawasan: isCentral ? null : _selectedLksdm,
      targetTimPusat: isCentral ? _selectedPusatTeam : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tktNo = widget.question.ticketNumber ?? '#${widget.question.id}';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Dialog
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.replay_rounded,
                        color: Colors.amber.shade900,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buka Kembali Tiket',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Aktifkan kembali tiket yang telah dinyatakan Selesai',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.slate400),
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context, false),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Ringkasan Tiket
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tktNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Text(
                              'Status Saat Ini: SELESAI',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.question.judul,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pelapor: ${widget.question.user?.name ?? "Pegawai"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Pilihan Target Disposisi Utama
                const Text(
                  'Arahkan Penanganan Tiket Kembali Ke: *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 8),
                _targetDestinationTile(
                  key: 'lksdm',
                  title: 'Staf Layanan Kawasan SDM (LKSDM)',
                  subtitle: 'Kembalikan ke antrean penanganan wilayah LKSDM',
                ),
                const SizedBox(height: 8),
                _targetDestinationTile(
                  key: 'pusat',
                  title: 'Staf Layanan SDM Pusat (BOSDM Pusat)',
                  subtitle: 'Eskalasi langsung ke tim spesialisasi kantor pusat',
                ),
                const SizedBox(height: 12),

                // Dropdown Pilihan Spesifik (Kawasan LKSDM atau Tim Pusat)
                if (_targetType == 'lksdm') ...[
                  const Text(
                    'Pilih Kawasan LKSDM Tujuan: *',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLksdm,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate800,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: LksdmCatalogData.allLksdm.map((lksdm) {
                      return DropdownMenuItem<String>(
                        value: lksdm.shortName,
                        child: Text(
                          '${lksdm.shortName} - ${lksdm.name.split(':').last.trim()}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLksdm = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const Text(
                    'Pilih Tim Kerja Pusat Tujuan: *',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPusatTeam,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate800,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: TusiCatalogData.centralTeams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team,
                        child: Text(
                          team,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPusatTeam = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Catatan / Alasan Pembukaan Kembali
                const Text(
                  'Alasan Pembukaan Kembali Tiket *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText:
                        'Misal: Bukti dukung baru telah diajukan; kendala belum terselesaikan sepenuhnya.',
                    hintStyle: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide: const BorderSide(
                        color: Colors.amber,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Catatan alasan wajib diisi untuk rekam audit sistem.';
                    }
                    if (val.trim().length < 5) {
                      return 'Jelaskan alasan secara singkat (minimal 5 karakter).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  'Catatan ini akan dicatat ke linimasa obrolan tiket dan staf tim yang dituju akan menerima notifikasi tugas.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.slate500,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),

                // Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: AppColors.slate600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _handleConfirm,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.replay_rounded, size: 18),
                      label: const Text(
                        'Aktifkan Kembali Tiket',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _targetDestinationTile({
    required String key,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _targetType == key;
    return InkWell(
      onTap: () => setState(() => _targetType = key),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade50 : AppColors.slate50,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.amber.shade900 : AppColors.slate400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.amber.shade900
                          : AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
