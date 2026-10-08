import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../questions/models/question_model.dart';
import '../../questions/services/question_service.dart';
import '../widgets/trending_chart_widget.dart';

class EksekutifDashboardScreen extends StatefulWidget {
  final UserModel user;

  const EksekutifDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<EksekutifDashboardScreen> createState() => _EksekutifDashboardScreenState();
}

class _EksekutifDashboardScreenState extends State<EksekutifDashboardScreen> {
  List<QuestionModel> allQuestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => isLoading = true);
    final questions = await QuestionService.getQuestions();
    if (mounted) {
      setState(() {
        allQuestions = questions;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryIndigo = Color(0xFF283593);

    final totalCount = allQuestions.length;
    final escalatedCount = allQuestions.where((q) => q.isEscalated).length;
    final lksdmCount = totalCount - escalatedCount;
    final closedCount = allQuestions.where((q) => q.isClosed).length;

    final lksdmRatio = totalCount > 0 ? ((lksdmCount / totalCount) * 100).toStringAsFixed(1) : '0';
    final escalatedRatio = totalCount > 0 ? ((escalatedCount / totalCount) * 100).toStringAsFixed(1) : '0';

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
                      color: primaryIndigo,
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
                      'PANEL EKSEKUTIF (MONITORING)',
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
        onRefresh: _loadMetrics,
        color: primaryIndigo,
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
                    Text(
                      'Selamat datang Pimpinan,',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 18),

                    // STATISTIK RINGKAS EKSEKUTIF (KPI REAL-TIME)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: primaryIndigo),
                              SizedBox(width: 8),
                              Text(
                                'Ringkasan KPI Layanan Kepegawaian',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (isLoading)
                            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                          else
                            Row(
                              children: [
                                _buildStatCard('Total Tiket', '$totalCount', Colors.blue),
                                const SizedBox(width: 8),
                                _buildStatCard('Penanganan LKSDM', '$lksdmRatio%', Colors.teal),
                                const SizedBox(width: 8),
                                _buildStatCard('Rasio Eskalasi', '$escalatedRatio%', Colors.amber.shade900),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // KARTU PENYELESAIAN TIKET
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.task_alt_rounded, color: Color(0xFF16A34A), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tingkat Penyelesaian Layanan', style: AppTypography.labelMedium),
                                const SizedBox(height: 2),
                                Text('$closedCount dari $totalCount tiket telah tuntas diselesaikan oleh pegawai.', style: AppTypography.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CHART TOPIK PERTANYAAN PALING BANYAK DITANYAKAN
                    const Text('Tren Topik Layanan Kepegawaian', style: AppTypography.heading3),
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

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
