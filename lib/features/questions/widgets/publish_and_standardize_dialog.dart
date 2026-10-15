import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../models/question_model.dart';
import '../services/question_normalizer_service.dart';
import '../services/question_service.dart';

class PublishAndStandardizeDialog extends StatefulWidget {
  final QuestionModel question;

  const PublishAndStandardizeDialog({
    super.key,
    required this.question,
  });

  static Future<QuestionModel?> show(BuildContext context, QuestionModel question) {
    return showModalBottomSheet<QuestionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PublishAndStandardizeDialog(question: question),
    );
  }

  @override
  State<PublishAndStandardizeDialog> createState() => _PublishAndStandardizeDialogState();
}

class _PublishAndStandardizeDialogState extends State<PublishAndStandardizeDialog> {
  late final TextEditingController _judulController;
  late final TextEditingController _isiController;
  late final NormalizedQuestionResult _normalizerResult;

  bool _showOriginal = false;
  bool _pinAsFaq = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _normalizerResult = QuestionNormalizerService.normalize(
      judul: widget.question.judul,
      isi: widget.question.isi,
    );

    _judulController = TextEditingController(text: _normalizerResult.normalizedJudul);
    _isiController = TextEditingController(text: _normalizerResult.normalizedIsi);
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  void _resetToOriginal() {
    setState(() {
      _judulController.text = widget.question.judul;
      _isiController.text = widget.question.isi;
    });
  }

  void _applyNormalizedSuggestion() {
    setState(() {
      _judulController.text = _normalizerResult.normalizedJudul;
      _isiController.text = _normalizerResult.normalizedIsi;
    });
  }

  Future<void> _handleSubmit() async {
    final finalJudul = _judulController.text.trim();
    final finalIsi = _isiController.text.trim();

    if (finalJudul.isEmpty || finalIsi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi pertanyaan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await QuestionService.publishAndStandardizeQuestion(
      questionId: widget.question.id ?? 0,
      standardizedJudul: finalJudul,
      standardizedIsi: finalIsi,
      originalJudul: widget.question.originalJudul ?? widget.question.judul,
      originalIsi: widget.question.originalIsi ?? widget.question.isi,
      makePublic: true,
      makePinned: _pinAsFaq,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final updatedQuestion = widget.question.copyWith(
          judul: finalJudul,
          isi: finalIsi,
          originalJudul: widget.question.originalJudul ?? widget.question.judul,
          originalIsi: widget.question.originalIsi ?? widget.question.isi,
          isPublic: true,
          isPinned: _pinAsFaq,
          isAnonymized: true,
        );
        Navigator.pop(context, updatedQuestion);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mempublikasikan pertanyaan. Silakan coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Dialog
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF512DA8).withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Color(0xFF512DA8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Up ke Publik & Bakukan',
                        style: AppTypography.heading2,
                      ),
                      Text(
                        'Publikasikan pertanyaan dengan bahasa baku resmi',
                        style: TextStyle(fontSize: 11, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Banner Proteksi Anonimitas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withAlpha(15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.primaryBlue.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: AppColors.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perlindungan Privasi Pegawai',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Identitas asli (${widget.question.user?.name ?? "Pegawai"}) akan disamarkan menjadi "Pegawai" saat tampil di Forum Publik.',
                          style: const TextStyle(fontSize: 11, color: AppColors.slate700, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Toggle Lihat Teks Asli Pegawai
            InkWell(
              onTap: () => setState(() => _showOriginal = !_showOriginal),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.slate600),
                        const SizedBox(width: 8),
                        Text(
                          _showOriginal ? 'Sembunyikan Teks Asli Pegawai' : 'Lihat Teks Asli Pegawai',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate700),
                        ),
                      ],
                    ),
                    Icon(
                      _showOriginal ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.slate600,
                    ),
                  ],
                ),
              ),
            ),

            if (_showOriginal) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.slate300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Judul Asli:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600)),
                    Text(widget.question.judul, style: const TextStyle(fontSize: 12.5, color: AppColors.slate800)),
                    const SizedBox(height: 6),
                    const Text('Isi Asli:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600)),
                    Text(widget.question.isi, style: const TextStyle(fontSize: 12, color: AppColors.slate800, height: 1.35)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Header Field Judul Baku
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Judul Pertanyaan Baku',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800),
                ),
                InkWell(
                  onTap: _applyNormalizedSuggestion,
                  child: const Text(
                    'Reset ke Saran Baku',
                    style: TextStyle(fontSize: 11, color: Color(0xFF512DA8), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                hintText: 'Judul pertanyaan formal...',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 14),

            // Header Field Isi Baku
            const Text(
              'Uraian Pertanyaan Baku (Resmi ASN)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _isiController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Uraian pertanyaan formal...',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),

            const SizedBox(height: 12),

            // Opsi Pin sebagai FAQ Tren
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _pinAsFaq,
              activeColor: Colors.amber.shade800,
              title: const Row(
                children: [
                  Icon(Icons.push_pin, size: 16, color: Colors.amber),
                  SizedBox(width: 6),
                  Text(
                    'Sematkan sebagai Topik Tren / FAQ Utama',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              subtitle: const Text(
                'Pertanyaan akan ditampilkan pada posisi atas dan tab FAQ Terpilih.',
                style: TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
              onChanged: (val) => setState(() => _pinAsFaq = val ?? true),
            ),

            const SizedBox(height: 16),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    onPressed: _isSubmitting ? null : _resetToOriginal,
                    child: const Text('Gunakan Teks Asli', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF512DA8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.public, size: 16),
                              SizedBox(width: 6),
                              Text('Publikasikan ke Forum', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
