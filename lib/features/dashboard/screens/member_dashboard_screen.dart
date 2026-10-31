import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/models/user_model.dart';
import '../../questions/data/service_category_catalog.dart';
import '../../questions/models/question_model.dart';
import '../../questions/screens/ask_question_screen.dart';
import '../../questions/screens/member_tickets_screen.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../../notifications/widgets/notification_bell_widget.dart';
import '../widgets/dashboard_faq_widget.dart';
import '../../broadcasts/screens/broadcast_feed_screen.dart';
import '../../broadcasts/widgets/urgent_broadcast_dialog.dart';

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
  String _selectedCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMyQuestions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UrgentBroadcastDialog.checkAndShow(context, widget.user);
    });
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

    List<QuestionModel> displayedActiveTickets = activeTickets;
    if (_selectedCategoryFilter != 'all') {
      displayedActiveTickets = activeTickets
          .where((q) => q.displayCategory.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()))
          .toList();
    }

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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tiket Aktif',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.colorTextMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, size: 16, color: AppColors.colorTextMuted),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${activeTickets.length}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.colorPrimary,
                                    ),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tiket Selesai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.colorTextMuted,
                                          fontWeight: FontWeight.w600,
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

                  const SizedBox(height: 12),

                  // Banner Pengumuman LKSDM
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BroadcastFeedScreen(
                            currentUser: widget.user,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade800,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(Icons.campaign_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengumuman ${widget.user.effectiveLksdm}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Lihat siaran resmi dan berkas lampiran kawasan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Color(0xFF78350F)),
                        ],
                      ),
                    ),
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
                  const SizedBox(height: 10),

                  // Category Filter Chip Row (Semua, Kehadiran, Mutasi Unit, dsb)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryFilterChip(
                          id: 'all',
                          label: 'Semua Kategori',
                          count: activeTickets.length,
                        ),
                        const SizedBox(width: 6),
                        ...ServiceCategoryCatalog.defaultCategories.map((cat) {
                          final catCount = activeTickets
                              .where((q) => q.displayCategory.toLowerCase().contains(cat.nama.toLowerCase()))
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildCategoryFilterChip(
                              id: cat.nama,
                              label: cat.nama,
                              count: catCount,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.colorPrimary),
                      ),
                    )
                  else if (displayedActiveTickets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.colorSurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.colorBorder, width: 1),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.task_alt_rounded, size: 36, color: AppColors.colorSecondary),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategoryFilter == 'all'
                                ? 'Tidak ada tiket aktif yang berjalan.'
                                : 'Tidak ada tiket aktif pada kategori "$_selectedCategoryFilter".',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.colorText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
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
                      itemCount: displayedActiveTickets.length,
                      itemBuilder: (context, index) {
                        final q = displayedActiveTickets[index];
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

  Widget _buildCategoryFilterChip({
    required String id,
    required String label,
    int? count,
  }) {
    final isSelected = _selectedCategoryFilter == id;
    return InkWell(
      key: ValueKey('member_category_filter_$id'),
      onTap: () {
        setState(() {
          _selectedCategoryFilter = id;
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.colorPrimary : AppColors.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.colorPrimary : AppColors.colorBorder,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 11,
              color: isSelected ? Colors.white : AppColors.colorTextMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.colorText,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.colorPrimarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.colorPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
