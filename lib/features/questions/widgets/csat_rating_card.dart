import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';

class CsatRatingCard extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onRatingSubmitted;
  final bool isReadOnly;

  const CsatRatingCard({
    super.key,
    required this.question,
    this.onRatingSubmitted,
    this.isReadOnly = false,
  });

  @override
  State<CsatRatingCard> createState() => _CsatRatingCardState();
}

class _CsatRatingCardState extends State<CsatRatingCard> {
  int _selectedRating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  static const List<String> _availableTags = [
    'Staf Ramah & Solutif',
    'Jawaban Jelas & Akurat',
    'Respon Cepat (Gercep)',
    'Aplikasi Mudah Digunakan',
  ];

  final Set<String> _selectedTags = {
    'Staf Ramah & Solutif',
    'Jawaban Jelas & Akurat',
    'Respon Cepat (Gercep)',
  };

  final List<String> _ratingLabels = [
    'Sangat Kecewa',
    'Kurang Puas',
    'Cukup',
    'Puas',
    'Sangat Puas',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitCsat() async {
    if (widget.question.id == null) return;
    setState(() => _isSubmitting = true);

    final success = await QuestionService.submitRating(
      questionId: widget.question.id!,
      rating: _selectedRating,
      feedback: _feedbackController.text.trim(),
      tags: _selectedTags.join(', '),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih atas penilaian dan ulasan layanan Anda!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        widget.onRatingSubmitted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim penilaian. Silakan coba lagi.'),
            backgroundColor: AppColors.colorPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingRating = widget.question.rating;

    // Jika mode read-only dan tiket belum dinilai oleh pengaju, jangan tampilkan form survei
    if (widget.isReadOnly && (existingRating == null || existingRating <= 0)) {
      return const SizedBox.shrink();
    }

    // Jika sudah pernah dinilai oleh user
    if (existingRating != null && existingRating > 0) {
      final tags = widget.question.ratingTagsList;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Survei Kepuasan Layanan (CSAT)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.isReadOnly ? 'Dinilai Pengaju' : 'Telah Dinilai',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final isFilled = index < existingRating;
                return Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? const Color(0xFFEAB308) : AppColors.slate300,
                  size: 24,
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              'Nilai: $existingRating / 5 (${_ratingLabels[(existingRating - 1).clamp(0, 4)]})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, size: 12, color: Color(0xFF15803D)),
                        const SizedBox(width: 4),
                        Text(
                          t,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (widget.question.ratingFeedback != null &&
                widget.question.ratingFeedback!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(204),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                ),
                child: Text(
                  'Ulasan: "${widget.question.ratingFeedback}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Jika belum dinilai (Form Penilaian Interaktif)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.star_rate_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Survei Kepuasan Layanan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      'Bagaimana penilaian Anda terhadap penanganan tiket dan aplikasi ini?',
                      style: TextStyle(fontSize: 11, color: AppColors.slate600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bintang Interaktif 1-5
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= _selectedRating;

              return IconButton(
                onPressed: () => setState(() => _selectedRating = starValue),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? const Color(0xFFEAB308) : AppColors.slate300,
                  size: 32,
                ),
                splashRadius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }),
          ),
          Center(
            child: Text(
              _ratingLabels[_selectedRating - 1],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Satisfaction Tags Pilihan
          const Text(
            'Aspek Layanan yang Dinilai:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return InkWell(
                onTap: () => _toggleTag(tag),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDCFCE7) : AppColors.slate100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF22C55E) : AppColors.slate300,
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        size: 14,
                        color: isSelected ? const Color(0xFF15803D) : AppColors.slate500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF15803D) : AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Field Catatan / Saran
          TextField(
            controller: _feedbackController,
            maxLines: 2,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tuliskan masukan atau ulasan terkait penanganan staf atau aplikasi (opsional)...',
              hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.slate400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1.2),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitCsat,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Penilaian'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
