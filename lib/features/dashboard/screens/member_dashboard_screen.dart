import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/models/user_model.dart';
import '../../questions/models/question_model.dart';
import '../../questions/screens/ask_question_screen.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../widgets/trending_chart_widget.dart';

class MemberDashboardScreen extends StatefulWidget {
  final UserModel user;

  const MemberDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  List<QuestionModel> myQuestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyQuestions();
  }

  Future<void> _loadMyQuestions() async {
    setState(() => isLoading = true);
    final questions = await QuestionService.getMyQuestions(token: widget.user.token);
    if (mounted) {
      setState(() {
        myQuestions = questions;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTickets = myQuestions.where((q) => q.isActive).toList();
    final closedTickets = myQuestions.where((q) => q.isClosed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          children: [
            Image.asset(
              AppConstants.logoAssetPath,
              height: 32,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                AppConstants.appTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyQuestions,
        color: AppColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Greeting Header
                  const Text(
                    'Selamat datang kembali,',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.user.name,
                    style: AppTypography.heading1,
                  ),

                  const SizedBox(height: 20),

                  // 2. Summary KPI Cards (Aktif vs Selesai)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.mark_chat_unread_outlined, color: Color(0xFF0284C7), size: 18),
                                  SizedBox(width: 6),
                                  Text('Tiket Aktif', style: TextStyle(fontSize: 12, color: AppColors.slate600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${activeTickets.length}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                                  SizedBox(width: 6),
                                  Text('Tiket Selesai', style: TextStyle(fontSize: 12, color: AppColors.slate600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${closedTickets.length}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. CTA Ajukan Pertanyaan Baru
                  CustomButton(
                    text: 'Ajukan Pertanyaan Baru',
                    icon: const Icon(Icons.add_comment_rounded),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AskQuestionScreen(token: widget.user.token ?? ''),
                        ),
                      );
                      _loadMyQuestions();
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. Section Tiket Aktif Berjalan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiket Aktif Berjalan',
                        style: AppTypography.heading3,
                      ),
                      if (activeTickets.isNotEmpty)
                        Text(
                          '${activeTickets.length} Tiket',
                          style: AppTypography.caption.copyWith(color: AppColors.slate500),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.primaryRed),
                      ),
                    )
                  else if (activeTickets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.task_alt_rounded, size: 36, color: Color(0xFF16A34A)),
                          SizedBox(height: 8),
                          Text(
                            'Tidak ada tiket aktif yang berjalan.',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pertanyaan yang Anda ajukan akan diproses oleh Staf Admin LKSDM Kawasan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeTickets.length,
                      itemBuilder: (context, index) {
                        final q = activeTickets[index];
                        return QuestionCard(
                          question: q,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuestionDetailScreen(
                                  question: q,
                                  currentUser: widget.user,
                                ),
                              ),
                            );
                            _loadMyQuestions();
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // 5. Section Pertanyaan Populer / FAQ
                  const Text(
                    'Pertanyaan Populer / FAQ',
                    style: AppTypography.heading3,
                  ),
                  const SizedBox(height: 12),
                  const TrendingChartWidget(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
