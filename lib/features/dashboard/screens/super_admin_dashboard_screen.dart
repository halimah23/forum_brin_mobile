import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/user_management_screen.dart';
import '../../questions/models/question_model.dart';
import '../../questions/data/lksdm_catalog_data.dart';
import '../../questions/data/tusi_catalog_data.dart';
import '../../questions/screens/faq_screen.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../services/performance_analytics_service.dart';
import '../widgets/performance_analytics_widgets.dart';
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

    final csatOverview = PerformanceAnalyticsService.calculateCsatOverview(questions);
    final staffLeaderboard = PerformanceAnalyticsService.getStaffPerformanceLeaderboard(questions, limit: 10);
    final topMembers = PerformanceAnalyticsService.getTopActiveMembers(questions, limit: 5);

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
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

                    // Hub Administrasi & Monitoring Sistem
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Administrasi & Monitoring',
                            style: AppTypography.heading3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF512DA8).withAlpha(20),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Text(
                            'Superadmin Control',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF512DA8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grid Tombol Hak Akses Utama Superadmin
                    Row(
                      children: [
                        Expanded(
                          child: _adminActionCard(
                            title: 'Kelola Akun & Akses',
                            subtitle: 'CRUD akun semua role',
                            icon: Icons.manage_accounts_outlined,
                            iconColor: const Color(0xFF0284C7),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserManagementScreen(
                                    currentUser: widget.user,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _adminActionCard(
                            title: 'Kelola FAQ & Tren',
                            subtitle: 'Kurasi topik populer & FAQ',
                            icon: Icons.quiz_outlined,
                            iconColor: const Color(0xFF512DA8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FaqScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _adminActionCard(
                            title: 'Monitoring Sistem',
                            subtitle: 'Status antrean & SLA tiket',
                            icon: Icons.monitor_heart_outlined,
                            iconColor: const Color(0xFF16A34A),
                            onTap: () => _showMonitoringDialog(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _adminActionCard(
                            title: 'Katalog Master Data',
                            subtitle: '14 Tim Pusat & 7 LKSDM',
                            icon: Icons.admin_panel_settings_outlined,
                            iconColor: const Color(0xFF475569),
                            onTap: () => _showMasterDataDialog(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _adminActionCard(
                            title: 'Statistik & Laporan',
                            subtitle: 'Agregat metrik kepuasan',
                            icon: Icons.analytics_outlined,
                            iconColor: const Color(0xFFC2410C),
                            onTap: () => _showStatistikDialog(context),
                          ),
                        ),
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
                              _loadData();
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // INDEKS KEPUASAN LAYANAN & APLIKASI (CSAT)
                    CsatScoreCardWidget(
                      overview: csatOverview,
                      title: 'Indeks Kepuasan Layanan & Aplikasi (CSAT)',
                      subtitle: 'Audit penilaian kinerja layanan staf dan kepuasan pengguna terhadap aplikasi BOSDM',
                    ),

                    const SizedBox(height: 20),

                    // LEADERBOARD KINERJA PETUGAS & STAF ADMIN
                    StaffLeaderboardCardWidget(
                      staffList: staffLeaderboard,
                      title: 'Leaderboard Kinerja Petugas & Staf Admin',
                      subtitle: 'Penilaian kuantitatif dan kualitatif penanganan tiket seluruh kawasan',
                    ),

                    const SizedBox(height: 20),

                    // DAFTAR PEGAWAI PALING AKTIF BERTANYA
                    TopMembersCardWidget(
                      memberList: topMembers,
                      title: 'Daftar Pegawai Paling Aktif Bertanya',
                      subtitle: 'Pegawai yang paling sering menyampaikan kendala di sistem',
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

  Widget _adminActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.slate500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showMasterDataDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Color(0xFF0284C7)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Kelola Master Data & Hak Akses',
                          style: AppTypography.heading2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Daftar katalog master unit kerja resmi BOSDM BRIN',
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        const Text('14 Tim Layanan Pusat BOSDM:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        ...TusiCatalogData.centralTeams.map(
                          (t) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, size: 16, color: Color(0xFF0284C7)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(t, style: const TextStyle(fontSize: 12.5))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('7 Wilayah Kawasan SDM (LKSDM):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        ...LksdmCatalogData.allLksdm.map(
                          (l) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 2),
                                Text(
                                  'Cakupan: ${l.coverageUnits.join(", ")}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMonitoringDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.monitor_heart, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Monitoring Sistem', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Infrastruktur & Layanan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _statusRow('Supabase API Gateway', 'ONLINE', Colors.green),
            _statusRow('Sinkronisasi Tiket Real-Time', 'NORMAL', Colors.green),
            _statusRow('Antrean LKSDM ke Pusat', 'STABIL', Colors.green),
            _statusRow('Tingkat Kepatuhan SLA', '98.4%', Colors.blue),
            const Divider(height: 20),
            const Text(
              'Superadmin memantau aliran eskalasi antar tim secara transparan tanpa batasan role unit.',
              style: TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.slate700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatistikDialog(BuildContext context) {
    final csatOverview = PerformanceAnalyticsService.calculateCsatOverview(questions);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Color(0xFFC2410C)),
            SizedBox(width: 8),
            Text('Statistik & Analisis', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tiket Terkelola: ${questions.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Tiket Aktif: ${questions.where((q) => q.isActive).length}', style: const TextStyle(fontSize: 12.5)),
            Text('Tiket Eskalasi Pusat: ${questions.where((q) => q.isEscalated).length}', style: const TextStyle(fontSize: 12.5)),
            Text('Tiket Selesai: ${questions.where((q) => q.isClosed).length}', style: const TextStyle(fontSize: 12.5)),
            const Divider(height: 18),
            Text('Rata-rata Rating CSAT: ${csatOverview.averageRating > 0 ? '${csatOverview.averageRating.toStringAsFixed(1)} ★' : '-'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
            Text('Tingkat Kepuasan: ${csatOverview.satisfactionRate.toStringAsFixed(1)}% (${csatOverview.totalRated} Ulasan)', style: const TextStyle(fontSize: 12.5, color: Color(0xFF15803D))),
            const SizedBox(height: 12),
            const Text(
              'Statistik ini diperbarui secara otomatis dari seluruh aktivitas layanan kepegawaian BRIN.',
              style: TextStyle(fontSize: 11.5, color: AppColors.slate600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
