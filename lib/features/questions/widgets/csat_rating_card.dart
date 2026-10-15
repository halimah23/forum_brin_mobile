import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';

class CsatRatingCard extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onRatingSubmitted;

  const CsatRatingCard({
    super.key,
    required this.question,
    this.onRatingSubmitted,
  });

  @override
  State<CsatRatingCard> createState() => _CsatRatingCardState();
}

class _CsatRatingCardState extends State<CsatRatingCard> {
  int _selectedRating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

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

  Future<void> _submitCsat() async {
    if (widget.question.id == null) return;
    setState(() => _isSubmitting = true);

    final success = await QuestionService.submitRating(
      questionId: widget.question.id!,
      rating: _selectedRating,
      feedback: _feedbackController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih atas penilaian dan ulasan Anda!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        widget.onRatingSubmitted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim penilaian. Silakan coba lagi.'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingRating = widget.question.rating;

    // Jika sudah pernah dinilai oleh user
    if (existingRating != null && existingRating > 0) {
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
                  child: const Text(
                    'Telah Dinilai',
                    style: TextStyle(
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
            if (widget.question.ratingFeedback != null &&
                widget.question.ratingFeedback!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ulasan: "${widget.question.ratingFeedback}"',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.slate700,
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
                      'Bagaimana penilaian Anda terhadap penanganan tiket ini?',
                      style: TextStyle(fontSize: 11, color: AppColors.slate600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
          // Field Catatan / Saran
          TextField(
            controller: _feedbackController,
            maxLines: 2,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tuliskan masukan atau catatan untuk layanan BOSDM (opsional)...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 12),
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
                backgroundColor: AppColors.primaryRed,
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
