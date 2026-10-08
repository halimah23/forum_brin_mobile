import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../questions/models/question_model.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../widgets/trending_chart_widget.dart';

class KetuaTimDashboardScreen extends StatefulWidget {
  final UserModel user;

  const KetuaTimDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<KetuaTimDashboardScreen> createState() => _KetuaTimDashboardScreenState();
}

class _KetuaTimDashboardScreenState extends State<KetuaTimDashboardScreen> {
  List<QuestionModel> teamQuestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final teamName = widget.user.tim ?? 'Tim Layanan SDM BOSDM';
    final list = await QuestionService.getQuestions(teamFilter: teamName);
    if (mounted) {
      setState(() {
        teamQuestions = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryTeal = Colors.teal.shade800;
    final teamName = widget.user.tim ?? 'Tim Layanan SDM BOSDM';

    final totalCount = teamQuestions.length;
    final pendingCount = teamQuestions.where((q) => q.ticketStatus.dbKey == 'OPEN').length;
    final inProgressCount = teamQuestions.where((q) => q.isActive && q.ticketStatus.dbKey != 'OPEN').length;
    final closedCount = teamQuestions.where((q) => q.isClosed).length;
    final pendingList = teamQuestions.where((q) => q.ticketStatus.dbKey == 'OPEN').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              AppConstants.logoAssetPath,
              height: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryTeal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: Text(
                      'PANEL KETUA TIM ($teamName)',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Selamat datang Ketua Tim,',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 4 Real-time KPI Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _kpiTile('Total Tiket Tim', '$totalCount', AppColors.primaryBlue, Icons.inbox_rounded),
                        _kpiTile('Perlu Disposisi', '$pendingCount', const Color(0xFFD97706), Icons.hourglass_top_rounded),
                        _kpiTile('Sedang Diproses', '$inProgressCount', const Color(0xFF0D9488), Icons.engineering_rounded),
                        _kpiTile('Tiket Selesai', '$closedCount', const Color(0xFF16A34A), Icons.check_circle_rounded),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Antrean Perlu Disposisi
                    const Text(
                      'Antrean Perlu Disposisi',
                      style: AppTypography.heading3,
                    ),
                    const SizedBox(height: 10),

                    if (isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (pendingList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Semua tiket tim telah didisposisi/ditangani.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingList.length,
                        itemBuilder: (context, index) {
                          final q = pendingList[index];
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
                              _loadData();
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // Trending Chart Widget
                    const Text(
                      'Topik Pertanyaan Populer Tim',
                      style: AppTypography.heading3,
                    ),
                    const SizedBox(height: 10),
                    const TrendingChartWidget(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiTile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
