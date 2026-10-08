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

class SuperAdminDashboardScreen extends StatefulWidget {
  final UserModel user;

  const SuperAdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  List<QuestionModel> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final list = await QuestionService.getQuestions();
    if (mounted) {
      setState(() {
        questions = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = questions.length;
    final activeCount = questions.where((q) => q.isActive).length;
    final escalatedCount = questions.where((q) => q.isEscalated).length;
    final closedCount = questions.where((q) => q.isClosed).length;

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
                  const Text(
                    AppConstants.appTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: const Text(
                      'PANEL SUPER ADMIN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
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
        color: AppColors.primaryRed,
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
                    Text('Selamat datang,', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(widget.user.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 18),

                    // Audit Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _metricTile('Total Tiket System', '$totalCount', AppColors.primaryRed, Icons.storage_rounded),
                        _metricTile('Tiket Aktif Berjalan', '$activeCount', const Color(0xFF0284C7), Icons.pending_actions_rounded),
                        _metricTile('Tiket Eskalasi Pusat', '$escalatedCount', const Color(0xFFC2410C), Icons.alt_route_rounded),
                        _metricTile('Tiket Selesai / Closed', '$closedCount', const Color(0xFF16A34A), Icons.task_alt_rounded),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Audit Feed System
                    const Text('Audit Layanan Tiket Real-Time', style: AppTypography.heading3),
                    const SizedBox(height: 10),

                    if (isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primaryRed)))
                    else if (questions.isEmpty)
                      const Text('Belum ada tiket dalam sistem.', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: questions.length > 5 ? 5 : questions.length,
                        itemBuilder: (context, index) {
                          final q = questions[index];
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

                    // CHART TOPIK PERTANYAAN PALING BANYAK DITANYAKAN
                    const Text('Analisis Topik Populer FAQ', style: AppTypography.heading3),
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

  Widget _metricTile(String title, String value, Color color, IconData icon) {
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
