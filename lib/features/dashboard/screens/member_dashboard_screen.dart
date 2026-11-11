import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../auth/models/user_model.dart';
import '../../questions/data/service_category_catalog.dart';
import '../../questions/models/question_model.dart';
import '../../questions/models/ticket_status.dart';
import '../../questions/screens/ask_question_screen.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../../notifications/widgets/notification_bell_widget.dart';
import '../widgets/dashboard_faq_widget.dart';
import '../../broadcasts/screens/broadcast_feed_screen.dart';
import '../../broadcasts/widgets/urgent_broadcast_dialog.dart';

typedef SivitasDashboardScreen = MemberDashboardScreen;

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
  String _selectedStatusFilter = 'all_active'; // 'all_active', 'open', 'in_progress', 'closed'
  String _selectedCategoryFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyQuestions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UrgentBroadcastDialog.checkAndShow(context, widget.user);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final openTickets = myQuestions.where((q) => q.ticketStatus == TicketStatus.open || q.ticketStatus == TicketStatus.offHoursQueue).toList();
    final inProgressTickets = myQuestions.where((q) => q.isActive && q.ticketStatus != TicketStatus.open && q.ticketStatus != TicketStatus.offHoursQueue).toList();
    final closedTickets = myQuestions.where((q) => q.isClosed).toList();

    // 1. Filter by Status
    List<QuestionModel> displayedTickets;
    switch (_selectedStatusFilter) {
      case 'open':
        displayedTickets = openTickets;
        break;
      case 'in_progress':
        displayedTickets = inProgressTickets;
        break;
      case 'closed':
        displayedTickets = closedTickets;
        break;
      case 'all_active':
      default:
        displayedTickets = activeTickets;
        break;
    }

    // 2. Filter by Category
    if (_selectedCategoryFilter != 'all') {
      displayedTickets = displayedTickets
          .where((q) => q.displayCategory.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()))
          .toList();
    }

    // 3. Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      displayedTickets = displayedTickets.where((q) {
        final matchTitle = q.judul.toLowerCase().contains(query);
        final matchContent = q.isi.toLowerCase().contains(query);
        final matchNumber = (q.ticketNumber ?? '').toLowerCase().contains(query);
        final matchCat = q.displayCategory.toLowerCase().contains(query);
        final matchTeam = (q.targetTimPusat ?? q.targetTim ?? '').toLowerCase().contains(query);
        return matchTitle || matchContent || matchNumber || matchCat || matchTeam;
      }).toList();
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
              height: 28,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                AppConstants.appTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.colorPrimary,
                ),
                overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Compact Header: Greeting & Quick Action "Ajukan Pertanyaan"
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${widget.user.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeTickets.length} tiket aktif • ${closedTickets.length} selesai',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.colorTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add_comment_rounded, size: 16),
                        label: const Text(
                          'Buat Tiket',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2. Search Bar Langsung di Atas
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.colorSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.colorBorder),
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
                        hintText: 'Cari tiket, judul, nomor, topik...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.colorTextMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.colorTextMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.colorTextMuted),
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

                  // 3. Status Filter Chips (Aktif, Belum Ditangani, Sedang Ditangani, Selesai)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildStatusFilterChip(
                          id: 'all_active',
                          label: 'Aktif',
                          count: activeTickets.length,
                          color: AppColors.colorPrimary,
                        ),
                        const SizedBox(width: 6),
                        _buildStatusFilterChip(
                          id: 'open',
                          label: 'Belum Ditangani',
                          count: openTickets.length,
                          color: const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusFilterChip(
                          id: 'in_progress',
                          label: 'Sedang Ditangani',
                          count: inProgressTickets.length,
                          color: const Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusFilterChip(
                          id: 'closed',
                          label: 'Selesai',
                          count: closedTickets.length,
                          color: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. Kategori Filter Chip Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryFilterChip(
                          id: 'all',
                          label: 'Semua Kategori',
                        ),
                        const SizedBox(width: 6),
                        ...ServiceCategoryCatalog.defaultCategories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildCategoryFilterChip(
                              id: cat.nama,
                              label: cat.nama,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Header Section Tiket
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedStatusFilter == 'closed'
                            ? 'Daftar Tiket Selesai'
                            : _selectedStatusFilter == 'open'
                                ? 'Daftar Tiket Belum Ditangani'
                                : _selectedStatusFilter == 'in_progress'
                                    ? 'Daftar Tiket Sedang Ditangani'
                                    : 'Daftar Tiket Aktif',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.colorText,
                        ),
                      ),
                      Text(
                        '${displayedTickets.length} Tiket',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colorTextMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 6. LIST TIKET (Paling Teratas / Konten Utama)
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: CircularProgressIndicator(color: AppColors.colorPrimary),
                      ),
                    )
                  else if (displayedTickets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.colorSurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.colorBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : _selectedStatusFilter == 'closed'
                                    ? Icons.task_alt_rounded
                                    : Icons.inbox_outlined,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ditemukan tiket dengan kata kunci "$_searchQuery".'
                                : _selectedStatusFilter == 'closed'
                                    ? 'Belum ada riwayat tiket yang selesai.'
                                    : 'Tidak ada tiket pada status ini.',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.colorText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Coba periksa ejaan atau gunakan kata kunci lain.'
                                : 'Tiket yang diajukan akan diproses oleh Staf Admin LKSDM Kawasan.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: AppColors.colorTextMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedTickets.length,
                      itemBuilder: (context, index) {
                        final q = displayedTickets[index];
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

                  const SizedBox(height: 18),

                  // 7. Pengumuman LKSDM (Compact Banner di Bawah List)
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade800,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengumuman ${widget.user.effectiveLksdm}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF78350F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Lihat siaran resmi kawasan & unduh lampiran',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF78350F)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 8. FAQ / Pertanyaan Populer
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

  Widget _buildStatusFilterChip({
    required String id,
    required String label,
    required int count,
    required Color color,
  }) {
    final isSelected = _selectedStatusFilter == id;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = id),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? color : AppColors.colorBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.colorText,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.colorPrimary : AppColors.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.colorPrimary : AppColors.colorBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 10,
              color: isSelected ? Colors.white : AppColors.colorTextMuted,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.colorText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
