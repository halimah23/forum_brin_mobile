import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../questions/models/question_model.dart';
import '../../questions/models/ticket_status.dart';
import '../../questions/services/question_service.dart';
import '../services/performance_analytics_service.dart';
import '../widgets/performance_analytics_widgets.dart';
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
    final totalAnswersCount = allQuestions.fold<int>(0, (sum, q) => sum + (q.answers?.length ?? 0));
    final waitingCount = allQuestions.where((q) => q.ticketStatus == TicketStatus.open).length;
    final inProgressCount = allQuestions.where((q) => q.ticketStatus == TicketStatus.inProgress || q.ticketStatus == TicketStatus.waitingUser).length;
    final escalatedCount = allQuestions.where((q) => q.isEscalated).length;
    final closedCount = allQuestions.where((q) => q.isClosed).length;

    final lksdmCount = totalCount - escalatedCount;
    final lksdmRatio = totalCount > 0 ? ((lksdmCount / totalCount) * 100).toStringAsFixed(1) : '0';
    final escalatedRatio = totalCount > 0 ? ((escalatedCount / totalCount) * 100).toStringAsFixed(1) : '0';

    final csatOverview = PerformanceAnalyticsService.calculateCsatOverview(allQuestions);
    final topStaff = PerformanceAnalyticsService.getStaffPerformanceLeaderboard(allQuestions, limit: 5);
    final topMembers = PerformanceAnalyticsService.getTopActiveMembers(allQuestions, limit: 5);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
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
                    const SizedBox(height: 2),
                    Text(
                      'Pemantauan real-time tiket, pertanyaan, jawaban, status, dan eskalasi kepegawaian BRIN.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                          else ...[
                            Row(
                              children: [
                                _buildStatCard('Total Pertanyaan', '$totalCount', Colors.blue, Icons.help_outline_rounded),
                                const SizedBox(width: 8),
                                _buildStatCard('Total Jawaban/Respon', '$totalAnswersCount', const Color(0xFF7C3AED), Icons.forum_outlined),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatCard('Penanganan LKSDM', '$lksdmRatio%', Colors.teal, Icons.support_agent_rounded),
                                const SizedBox(width: 8),
                                _buildStatCard('Rasio Eskalasi Pusat', '$escalatedRatio%', Colors.amber.shade900, Icons.alt_route_rounded),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // PEMANTAUAN STATUS & ESKALASI TIKET
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
                              Icon(Icons.monitor_heart_outlined, color: primaryIndigo),
                              SizedBox(width: 8),
                              Text(
                                'Monitoring Status & Alur Eskalasi Tiket',
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
                                _buildStatusCard('Antrean LKSDM', '$waitingCount', TicketStatus.open.color, TicketStatus.open.icon),
                                const SizedBox(width: 6),
                                _buildStatusCard('Diproses LKSDM', '$inProgressCount', TicketStatus.inProgress.color, TicketStatus.inProgress.icon),
                                const SizedBox(width: 6),
                                _buildStatusCard('Eskalasi Pusat', '$escalatedCount', TicketStatus.escalated.color, TicketStatus.escalated.icon),
                                const SizedBox(width: 6),
                                _buildStatusCard('Selesai (Closed)', '$closedCount', TicketStatus.closed.color, TicketStatus.closed.icon),
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

                    const SizedBox(height: 20),

                    // INDEKS KEPUASAN LAYANAN NASIONAL (CSAT)
                    CsatScoreCardWidget(
                      overview: csatOverview,
                      title: 'Indeks Kepuasan Layanan Nasional BRIN (CSAT)',
                      subtitle: 'Hasil evaluasi kepuasan pegawai terhadap staf, kualitas jawaban, dan aplikasi BOSDM',
                    ),

                    const SizedBox(height: 20),

                    // KINERJA STAF & KETUA TIM TERBAIK
                    StaffLeaderboardCardWidget(
                      staffList: topStaff,
                      title: 'Petugas & Staf Berkinerja Terbaik',
                      subtitle: 'Petugas paling rutin, cepat merespons (gercep), dan ber-rating kepuasan tinggi',
                    ),

                    const SizedBox(height: 20),

                    // PEGAWAI PALING AKTIF BERKONSULTASI
                    TopMembersCardWidget(
                      memberList: topMembers,
                      title: 'Top Pegawai Paling Aktif Berkonsultasi',
                      subtitle: 'Pegawai yang paling sering mengajukan konsultasi & kendala kepegawaian',
                    ),

                    const SizedBox(height: 24),

                    // CHART TOPIK PERTANYAAN PALING BANYAK DITANYAKAN
                    const Text('Tren Topik Layanan Kepegawaian', style: AppTypography.heading3),
                    const SizedBox(height: 10),
                    const TrendingChartWidget(),

                    const SizedBox(height: 20),

                    // INFORMASI HAK AKSES EKSEKUTIF
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: primaryIndigo, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Akses Eksekutif: Memantau agregasi dashboard, pertanyaan, jawaban tim, status alur, eskalasi pusat, dan statistik respon secara terpusat (Read-Only).',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E1B4B), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

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

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withAlpha(60), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 8.5, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
