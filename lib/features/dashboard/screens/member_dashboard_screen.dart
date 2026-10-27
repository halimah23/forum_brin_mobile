import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/models/user_model.dart';
import '../../questions/models/question_model.dart';
import '../../questions/screens/ask_question_screen.dart';
import '../../questions/screens/member_tickets_screen.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../../notifications/widgets/notification_bell_widget.dart';
import '../widgets/dashboard_faq_widget.dart';

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
    final questions = await QuestionService.getMyQuestions(
      userId: widget.user.id?.toString(),
      token: widget.user.token,
    );
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
      backgroundColor: AppColors.colorBg,
      appBar: AppBar(
        backgroundColor: AppColors.colorSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          NotificationBellWidget(user: widget.user),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.colorBorder, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyQuestions,
        color: AppColors.colorPrimary,
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
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.colorTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorText,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Summary KPI Cards (Aktif vs Selesai)
                  Row(
                    children: [
                      // Card Tiket Aktif
                      Expanded(
                        child: Material(
                          color: AppColors.colorSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MemberTicketsScreen(
                                    user: widget.user,
                                    initialTabIndex: 0,
                                  ),
                                ),
                              );
                              _loadMyQuestions();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.colorBorder, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.mark_chat_unread_outlined, color: AppColors.colorPrimary, size: 18),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Tiket Aktif',
                                          style: TextStyle(fontSize: 12, color: AppColors.colorTextMuted, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, size: 16, color: AppColors.colorTextMuted),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${activeTickets.length}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.colorText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card Tiket Selesai
                      Expanded(
                        child: Material(
                          color: AppColors.colorSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MemberTicketsScreen(
                                    user: widget.user,
                                    initialTabIndex: 1,
                                  ),
                                ),
                              );
                              _loadMyQuestions();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.colorBorder, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded, color: AppColors.colorSecondary, size: 18),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Tiket Selesai',
                                          style: TextStyle(fontSize: 12, color: AppColors.colorTextMuted, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, size: 16, color: AppColors.colorTextMuted),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${closedTickets.length}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.colorText),
                                  ),
                                ],
                              ),
                            ),
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
                          builder: (context) => AskQuestionScreen(
                            token: widget.user.token ?? '',
                            user: widget.user,
                          ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.colorText,
                        ),
                      ),
                      if (activeTickets.isNotEmpty)
                        Text(
                          '${activeTickets.length} Tiket',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.colorTextMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.colorPrimary),
                      ),
                    )
                  else if (activeTickets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.colorSurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.colorBorder, width: 1),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.task_alt_rounded, size: 36, color: AppColors.colorSecondary),
                          SizedBox(height: 8),
                          Text(
                            'Tidak ada tiket aktif yang berjalan.',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.colorText),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pertanyaan yang Anda ajukan akan diproses oleh Staf Admin LKSDM Kawasan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppColors.colorTextMuted),
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
                          currentUser: widget.user,
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
                  DashboardFaqWidget(currentUser: widget.user),

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
