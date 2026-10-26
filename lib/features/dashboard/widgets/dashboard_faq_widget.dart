import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../questions/models/question_model.dart';
import '../../questions/screens/faq_detail_screen.dart';
import '../../questions/screens/faq_screen.dart';
import '../../questions/services/question_service.dart';

class DashboardFaqWidget extends StatefulWidget {
  final UserModel? currentUser;
  final List<QuestionModel>? preloadedQuestions;

  const DashboardFaqWidget({
    super.key,
    this.currentUser,
    this.preloadedQuestions,
  });

  @override
  State<DashboardFaqWidget> createState() => _DashboardFaqWidgetState();
}

class _DashboardFaqWidgetState extends State<DashboardFaqWidget> {
  List<QuestionModel> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  @override
  void didUpdateWidget(covariant DashboardFaqWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preloadedQuestions != oldWidget.preloadedQuestions) {
      _loadFaqs();
    }
  }

  Future<void> _loadFaqs() async {
    if (widget.preloadedQuestions != null && widget.preloadedQuestions!.isNotEmpty) {
      final filtered = widget.preloadedQuestions!
          .where((q) => q.isPublic && (q.isStandardized || q.hasSummary || q.isPinned))
          .toList();
      if (filtered.isNotEmpty) {
        if (mounted) {
          setState(() {
            _faqs = filtered;
            _isLoading = false;
          });
        }
        return;
      }
    }

    final results = await QuestionService.getFaqQuestions();
    if (mounted) {
      setState(() {
        _faqs = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topFaqs = _faqs.take(4).toList();

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
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pertanyaan Populer & FAQ Resmi',
                      style: AppTypography.heading3,
                    ),
                    Text(
                      'Solusi terverifikasi yang telah dibakukan oleh Tim BOSDM',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FaqScreen(currentUser: widget.currentUser),
                    ),
                  );
                  _loadFaqs();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primaryRed,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            )
          else if (topFaqs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.slate500),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada pertanyaan FAQ resmi yang dipublikasikan.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate600),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topFaqs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final faq = topFaqs[index];
                final summarySnippet = faq.hasSummary
                    ? faq.summaryJawaban!
                    : faq.effectiveOfficialSummary;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FaqDetailScreen(
                            question: faq,
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                      _loadFaqs();
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRed.withAlpha(20),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  faq.tugasFungsiNama ?? faq.effectiveTargetTim,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (faq.isPinned)
                                const Row(
                                  children: [
                                    Icon(Icons.push_pin, size: 10, color: Colors.amber),
                                    SizedBox(width: 2),
                                    Text(
                                      'FAQ Utama',
                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                    ),
                                  ],
                                ),
                              const Spacer(),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.slate400),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            faq.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    summarySnippet,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF166534),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
