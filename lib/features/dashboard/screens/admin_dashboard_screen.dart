import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_fab.dart';
import '../../auth/models/user_model.dart';
import '../../notifications/widgets/notification_bell_widget.dart';
import '../../questions/data/service_category_catalog.dart';
import '../../questions/models/question_model.dart';
import '../../questions/models/ticket_status.dart';
import '../../questions/screens/ask_question_screen.dart';
import '../../questions/screens/lksdm_consultation_tickets_screen.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../services/performance_analytics_service.dart';
import '../widgets/performance_analytics_widgets.dart';
import '../widgets/dashboard_faq_widget.dart';
import '../../broadcasts/screens/broadcast_management_screen.dart';
import '../../broadcasts/screens/create_broadcast_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<QuestionModel> teamQuestions = [];
  bool isLoading = true;
  String _selectedFilter = 'all_active';
  String _selectedCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final filter = widget.user.isAdminLksdm
        ? widget.user.effectiveLksdm
        : (widget.user.tim ?? 'Tim Layanan SDM BOSDM');
    final list = await QuestionService.getQuestions(teamFilter: filter);
    if (mounted) {
      setState(() {
        teamQuestions = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminLksdm = widget.user.isAdminLksdm;
    final lksdmName = widget.user.effectiveLksdm;
    final teamName = widget.user.tim ?? (isAdminLksdm ? lksdmName : 'Fungsi Pengelolaan data dan informasi SDM');
    final primaryColor = isAdminLksdm ? AppColors.colorSecondaryStrong : AppColors.colorPrimary;

    final allActiveQuestions = teamQuestions.where((q) => q.isActive).toList();
    final waitingQuestions = teamQuestions.where((q) => q.ticketStatus == TicketStatus.open).toList();
    final inProgressQuestions = teamQuestions.where((q) => q.isActive && q.ticketStatus != TicketStatus.open).toList();
    final closedQuestions = teamQuestions.where((q) => q.isClosed).toList();

    List<QuestionModel> displayedQuestions;
    switch (_selectedFilter) {
      case 'open':
        displayedQuestions = waitingQuestions;
        break;
      case 'in_progress':
        displayedQuestions = inProgressQuestions;
        break;
      case 'closed':
        displayedQuestions = closedQuestions;
        break;
      case 'all_active':
      default:
        displayedQuestions = allActiveQuestions;
        break;
    }

    final statusFilteredQuestions = displayedQuestions;
    if (_selectedCategoryFilter != 'all') {
      displayedQuestions = displayedQuestions
          .where((q) => q.displayCategory.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()))
          .toList();
    }

    final personalStat = PerformanceAnalyticsService.getStaffPersonalPerformance(
      teamQuestions,
      userId: widget.user.id ?? '',
      userName: widget.user.name,
      role: isAdminLksdm ? 'Staf Admin LKSDM' : 'Staf Admin Pusat',
      team: teamName,
    );
    final csatOverview = PerformanceAnalyticsService.calculateCsatOverview(teamQuestions);
    final topMembers = PerformanceAnalyticsService.getTopActiveMembers(teamQuestions, limit: 3);

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
                  Text(
                    AppConstants.appTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
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
                      isAdminLksdm ? 'STAF ADMIN LKSDM ($lksdmName)' : 'STAF ADMIN PUSAT ($teamName)',
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
        actions: [
          NotificationBellWidget(user: widget.user, iconColor: primaryColor),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      isAdminLksdm ? 'Selamat datang Staf Admin Kawasan,' : 'Selamat datang Staf Admin Pusat,',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Active Queue Banner Alert (Jika ada antrean tiket aktif)
                    if (waitingQuestions.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFFD97706), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${waitingQuestions.length} Antrean Tiket Aktif Memerlukan Respons',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ada tiket baru dari pegawai yang masuk ke wilayah $lksdmName dan siap ditindaklanjuti atau dijawab langsung.',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Metric Counters Row (Interactive Filter Cards)
                    Row(
                      children: [
                        _buildStatBox(
                          label: 'Semua Aktif',
                          value: '${allActiveQuestions.length}',
                          color: primaryColor,
                          icon: Icons.mark_chat_unread_outlined,
                          isSelected: _selectedFilter == 'all_active',
                          onTap: () => setState(() => _selectedFilter = 'all_active'),
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          label: 'Antrean Baru',
                          value: '${waitingQuestions.length}',
                          color: const Color(0xFFD97706),
                          icon: Icons.hourglass_top_rounded,
                          isSelected: _selectedFilter == 'open',
                          onTap: () => setState(() => _selectedFilter = 'open'),
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          label: 'Diproses',
                          value: '${inProgressQuestions.length}',
                          color: const Color(0xFF0D9488),
                          icon: Icons.support_agent_rounded,
                          isSelected: _selectedFilter == 'in_progress',
                          onTap: () => setState(() => _selectedFilter = 'in_progress'),
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          label: 'Selesai',
                          value: '${closedQuestions.length}',
                          color: const Color(0xFF16A34A),
                          icon: Icons.task_alt_rounded,
                          isSelected: _selectedFilter == 'closed',
                          onTap: () => setState(() => _selectedFilter = 'closed'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // KARTU RAPOR KINERJA PERSONAL STAF ADMIN
                    PersonalPerformanceCardWidget(personalStat: personalStat),

                    if (isAdminLksdm) ...[
                      const SizedBox(height: 16),
                      _buildLksdmBroadcastCard(context),
                      const SizedBox(height: 16),
                      _buildLksdmConsultationCard(context),
                    ],

                    const SizedBox(height: 20),

                    // DAFTAR TIKET SECTION & BULLET FILTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdminLksdm ? 'Daftar Tiket $lksdmName' : 'Daftar Tiket $teamName',
                                style: AppTypography.heading3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedFilter == 'all_active'
                                    ? 'Menampilkan semua tiket aktif (belum selesai)'
                                    : _selectedFilter == 'open'
                                        ? 'Menampilkan antrean tiket baru belum ditangani'
                                        : _selectedFilter == 'in_progress'
                                            ? 'Menampilkan tiket sedang dalam proses penanganan'
                                            : 'Menampilkan riwayat tiket selesai',
                                style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${displayedQuestions.length} Tiket',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Bullet Filter Bar (● Semua Aktif, ● Belum Ditangani, ● Sedang Ditangani, ● Selesai)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildBulletFilterChip(
                            id: 'all_active',
                            label: 'Semua Aktif',
                            count: allActiveQuestions.length,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          _buildBulletFilterChip(
                            id: 'open',
                            label: 'Belum Ditangani',
                            count: waitingQuestions.length,
                            color: const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          _buildBulletFilterChip(
                            id: 'in_progress',
                            label: 'Sedang Ditangani',
                            count: inProgressQuestions.length,
                            color: const Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 8),
                          _buildBulletFilterChip(
                            id: 'closed',
                            label: 'Selesai',
                            count: closedQuestions.length,
                            color: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category Filter Chip Row (Semua, Kehadiran, Mutasi Unit, dsb)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryFilterChip(
                            id: 'all',
                            label: 'Semua Kategori',
                            count: statusFilteredQuestions.length,
                          ),
                          const SizedBox(width: 6),
                          ...ServiceCategoryCatalog.defaultCategories.map((cat) {
                            final catCount = statusFilteredQuestions
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

                    if (!isLoading && displayedQuestions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFilter == 'closed'
                                  ? Icons.task_alt_rounded
                                  : Icons.inbox_outlined,
                              size: 36,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'all_active'
                                  ? 'Tidak ada tiket aktif saat ini untuk wilayah $lksdmName'
                                  : _selectedFilter == 'open'
                                      ? 'Tidak ada antrean baru yang belum ditangani'
                                      : _selectedFilter == 'in_progress'
                                          ? 'Belum ada tiket yang sedang dalam penanganan'
                                          : 'Belum ada tiket yang selesai',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedQuestions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final q = displayedQuestions[index];
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

                    // JOBDESK SCOPE CARD DARI CSV
                    Container(
                      padding: const EdgeInsets.all(14),
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
                              Icon(isAdminLksdm ? Icons.location_city : Icons.account_tree, color: primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAdminLksdm ? 'Cakupan Tugas & Fungsi $lksdmName' : 'Cakupan Tugas & Fungsi $teamName',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAdminLksdm
                                ? '• Penegakan hukuman disiplin ringan-sedang\n• Fasilitasi Kenaikan Gaji Berkala (KGB)\n• Monitoring Tugas Belajar & Kehadiran Pegawai Kawasan\n• Layanan kepegawaian kawasan & verifikasi layanan pusat'
                                : '• Penanganan eskalasi sesuai tupoksi $teamName\n• Penilaian & penetapan kebijakan tingkat pusat\n• Pendampingan percakapan tripartit (Pegawai + LKSDM + Tim Pusat)',
                            style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // INDEKS KEPUASAN LAYANAN (CSAT) WILAYAH / TIM
                    CsatScoreCardWidget(
                      overview: csatOverview,
                      title: isAdminLksdm ? 'CSAT Layanan $lksdmName' : 'CSAT Layanan $teamName',
                      subtitle: 'Hasil evaluasi kepuasan pegawai yang telah selesai dilayani',
                    ),

                    const SizedBox(height: 20),

                    // PEGAWAI PALING AKTIF BERKONSULTASI DI WILAYAH INI
                    TopMembersCardWidget(
                      memberList: topMembers,
                      title: 'Pegawai Paling Sering Berkonsultasi',
                      subtitle: 'Pegawai yang aktif berinteraksi dengan staf pada tiket',
                    ),

                    const SizedBox(height: 24),

                    // CHART TOPIK PERTANYAAN PALING BANYAK DITANYAKAN
                    DashboardFaqWidget(currentUser: widget.user),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: isAdminLksdm
          ? CustomFab(
              label: 'Konsultasi ke Pusat',
              backgroundColor: Colors.purple.shade800,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AskQuestionScreen(
                      token: widget.user.token ?? '',
                      user: widget.user,
                      isLksdmConsultation: true,
                    ),
                  ),
                );
                _loadData();
              },
            )
          : null,
    );
  }

  Widget _buildLksdmConsultationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.purple.shade100.withAlpha(120),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.purple.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade700,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.send_and_archive_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konsultasi Mandiri ke Pusat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF581C87),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ajukan konsultasi regulasi atau kendala teknis langsung ke Tim Pusat BOSDM',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple.shade900,
                    side: BorderSide(color: Colors.purple.shade400),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.inbox_outlined, size: 16),
                  label: const Text(
                    'Tiket Saya',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LksdmConsultationTicketsScreen(user: widget.user),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Konsultasi Baru',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AskQuestionScreen(
                          token: widget.user.token ?? '',
                          user: widget.user,
                          isLksdmConsultation: true,
                        ),
                      ),
                    );
                    _loadData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLksdmBroadcastCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50.withAlpha(160),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.amber.shade300, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade800,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast Notifikasi ${widget.user.effectiveLksdm}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Siarkan pengumuman resmi dan berkas lampiran ke pegawai kawasan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF78350F),
                    side: BorderSide(color: Colors.amber.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text(
                    'Kelola & Riwayat',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BroadcastManagementScreen(
                          currentUser: widget.user,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Buat Siaran',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateBroadcastScreen(
                          currentUser: widget.user,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulletFilterChip({
    required String id,
    required String label,
    required int count,
    required Color color,
  }) {
    final isSelected = _selectedFilter == id;
    return InkWell(
      key: ValueKey('bullet_filter_$id'),
      onTap: () {
        setState(() {
          _selectedFilter = id;
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.slate700,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : AppColors.slate600,
                ),
              ),
            ),
          ],
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
      key: ValueKey('category_filter_$id'),
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
          color: isSelected ? AppColors.slate900 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.slate900 : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 11,
              color: isSelected ? Colors.white : AppColors.slate500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.slate700,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.slate600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : AppColors.slate600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
