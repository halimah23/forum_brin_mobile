import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_fab.dart';
import '../../auth/models/user_model.dart';
import '../../questions/data/service_category_catalog.dart';
import '../../questions/models/question_model.dart';
import '../../questions/models/ticket_status.dart';
import '../../questions/screens/ask_question_screen.dart';
import '../../questions/screens/lksdm_consultation_tickets_screen.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../../notifications/widgets/notification_bell_widget.dart';
import '../services/performance_analytics_service.dart';
import '../widgets/performance_analytics_widgets.dart';
import '../widgets/dashboard_faq_widget.dart';
import '../../broadcasts/screens/broadcast_management_screen.dart';
import '../../broadcasts/screens/create_broadcast_screen.dart';

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
  String _selectedFilter = 'all_active';
  String _selectedCategoryFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final filter = widget.user.isKetuaTimLksdm
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
    final primaryTeal = Colors.teal.shade800;
    final teamName = widget.user.isKetuaTimLksdm
        ? widget.user.effectiveLksdm
        : (widget.user.tim ?? 'Tim Layanan SDM BOSDM');

    final allActiveQuestions = teamQuestions.where((q) => q.isActive).toList();
    final pendingQuestions = teamQuestions.where((q) => q.ticketStatus == TicketStatus.open || q.ticketStatus == TicketStatus.offHoursQueue).toList();
    final inProgressQuestions = teamQuestions.where((q) => q.isActive && q.ticketStatus != TicketStatus.open && q.ticketStatus != TicketStatus.offHoursQueue && q.ticketStatus != TicketStatus.escalated && q.ticketStatus != TicketStatus.inProgressCenter).toList();
    final escalatedQuestions = teamQuestions.where((q) => q.ticketStatus == TicketStatus.escalated || q.ticketStatus == TicketStatus.inProgressCenter).toList();
    final closedQuestions = teamQuestions.where((q) => q.isClosed).toList();

    List<QuestionModel> displayedQuestions;
    switch (_selectedFilter) {
      case 'open':
        displayedQuestions = pendingQuestions;
        break;
      case 'in_progress':
        displayedQuestions = inProgressQuestions;
        break;
      case 'escalated':
        displayedQuestions = escalatedQuestions;
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

    if (_searchQuery.trim().isNotEmpty) {
      final qLower = _searchQuery.trim().toLowerCase();
      displayedQuestions = displayedQuestions.where((q) {
        final matchTitle = q.judul.toLowerCase().contains(qLower);
        final matchContent = q.isi.toLowerCase().contains(qLower);
        final matchTicket = (q.ticketNumber ?? '').toLowerCase().contains(qLower);
        final matchCat = q.displayCategory.toLowerCase().contains(qLower);
        final matchAuthor = q.officialAuthorName.toLowerCase().contains(qLower);
        final matchLksdm = q.authorAsalLksdm.toLowerCase().contains(qLower);
        return matchTitle || matchContent || matchTicket || matchCat || matchAuthor || matchLksdm;
      }).toList();
    }

    final csatOverview = PerformanceAnalyticsService.calculateCsatOverview(teamQuestions);
    final staffLeaderboard = PerformanceAnalyticsService.getStaffPerformanceLeaderboard(teamQuestions, limit: 5);
    final topMembers = PerformanceAnalyticsService.getTopActiveMembers(teamQuestions, limit: 5);

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
        actions: [
          NotificationBellWidget(user: widget.user, iconColor: primaryTeal),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
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
                    // 1. Compact Greeting Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${widget.user.name}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.user.isKetuaTimLksdm
                                    ? 'Ketua Tim Kawasan • $teamName'
                                    : 'Ketua Tim Pusat • $teamName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${allActiveQuestions.length} Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 2. Search Bar Langsung di Atas Beranda
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari tiket, judul, nomor, pengaju...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.slate400),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.slate400),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 3. Bullet Filter Chips (Aktif, Belum Ditangani, Sedang Ditangani, Eskalasi Pusat, Selesai)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildBulletFilterChip(
                            id: 'all_active',
                            label: 'Aktif',
                            count: allActiveQuestions.length,
                            color: primaryTeal,
                          ),
                          const SizedBox(width: 6),
                          _buildBulletFilterChip(
                            id: 'open',
                            label: 'Belum Ditangani',
                            count: pendingQuestions.length,
                            color: const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          _buildBulletFilterChip(
                            id: 'in_progress',
                            label: 'Sedang Ditangani',
                            count: inProgressQuestions.length,
                            color: const Color(0xFF0D9488),
                          ),
                          if (widget.user.isKetuaTimLksdm) ...[
                            const SizedBox(width: 6),
                            _buildBulletFilterChip(
                              id: 'escalated',
                              label: 'Eskalasi Pusat',
                              count: escalatedQuestions.length,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ],
                          const SizedBox(width: 6),
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

                    // 4. Category Filter Chip Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
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

                    // 5. Header Section Daftar Tiket Layanan Tim (Paling Teratas)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daftar Tiket Layanan Tim',
                                style: AppTypography.heading3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedFilter == 'all_active'
                                    ? 'Menampilkan semua tiket aktif (belum selesai)'
                                    : _selectedFilter == 'open'
                                        ? 'Menampilkan antrean tiket yang perlu disposisi'
                                        : _selectedFilter == 'in_progress'
                                            ? 'Menampilkan tiket sedang ditangani tim'
                                            : _selectedFilter == 'escalated'
                                                ? 'Menampilkan tiket dialihkan ke pusat'
                                                : 'Menampilkan riwayat tiket selesai',
                                style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${displayedQuestions.length} Tiket',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 6. LISTING TIKET LANGSUNG PALING TERATAS
                    if (isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (displayedQuestions.isEmpty)
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
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : _selectedFilter == 'closed'
                                      ? Icons.task_alt_rounded
                                      : Icons.inbox_outlined,
                              size: 36,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ditemukan tiket dengan kata kunci "$_searchQuery".'
                                  : _selectedFilter == 'all_active'
                                      ? 'Tidak ada tiket aktif saat ini. Semua tiket tim telah tuntas.'
                                      : _selectedFilter == 'open'
                                          ? 'Semua tiket tim telah didisposisi/ditangani.'
                                          : _selectedFilter == 'in_progress'
                                              ? 'Belum ada tiket yang sedang dalam penanganan aktif.'
                                              : _selectedFilter == 'escalated'
                                                  ? 'Belum ada tiket yang dialihkan ke pusat.'
                                                  : 'Belum ada riwayat tiket selesai.',
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

                    const SizedBox(height: 18),

                    // 7. 4 Real-time KPI Cards (Interactive Filters)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _kpiTile(
                          'Semua Aktif',
                          '${allActiveQuestions.length}',
                          primaryTeal,
                          Icons.mark_chat_unread_outlined,
                          isSelected: _selectedFilter == 'all_active',
                          onTap: () => setState(() => _selectedFilter = 'all_active'),
                        ),
                        _kpiTile(
                          'Belum Ditangani',
                          '${pendingQuestions.length}',
                          const Color(0xFFD97706),
                          Icons.hourglass_top_rounded,
                          isSelected: _selectedFilter == 'open',
                          onTap: () => setState(() => _selectedFilter = 'open'),
                        ),
                        _kpiTile(
                          'Sedang Ditangani',
                          '${inProgressQuestions.length}',
                          const Color(0xFF0D9488),
                          Icons.engineering_rounded,
                          isSelected: _selectedFilter == 'in_progress',
                          onTap: () => setState(() => _selectedFilter = 'in_progress'),
                        ),
                        _kpiTile(
                          'Selesai',
                          '${closedQuestions.length}',
                          const Color(0xFF16A34A),
                          Icons.check_circle_rounded,
                          isSelected: _selectedFilter == 'closed',
                          onTap: () => setState(() => _selectedFilter = 'closed'),
                        ),
                      ],
                    ),

                    if (widget.user.isKetuaTimLksdm) ...[
                      const SizedBox(height: 16),
                      _buildLksdmBroadcastCard(context),
                      const SizedBox(height: 16),
                      _buildLksdmConsultationCard(context),
                    ],

                    const SizedBox(height: 20),

                    // INDEKS KEPUASAN LAYANAN TIM
                    CsatScoreCardWidget(
                      overview: csatOverview,
                      title: 'Indeks Kepuasan Layanan Tim ($teamName)',
                      subtitle: 'Skor CSAT dan aspek penilaian layanan dari pegawai yang tuntas dibantu',
                    ),

                    const SizedBox(height: 20),

                    // KINERJA STAF TIM (GERCEP & RATING TINGGI)
                    StaffLeaderboardCardWidget(
                      staffList: staffLeaderboard,
                      title: 'Kinerja Staf Tim ($teamName)',
                      subtitle: 'Staf tim paling aktif, responsif (gercep), dan ber-rating tinggi',
                    ),

                    const SizedBox(height: 20),

                    // TOP PEGAWAI BERKONSULTASI KE TIM INI
                    TopMembersCardWidget(
                      memberList: topMembers,
                      title: 'Pegawai Paling Sering Berkonsultasi',
                      subtitle: 'Pegawai yang paling sering meminta pendampingan ke tim ini',
                    ),

                    const SizedBox(height: 24),

                    // Trending Chart Widget
                    DashboardFaqWidget(currentUser: widget.user),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: widget.user.isKetuaTimLksdm
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

  Widget _kpiTile(
    String title,
    String value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
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
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : AppColors.slate600,
                    ),
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
      ),
    );
  }
}
