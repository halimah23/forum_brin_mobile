import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../auth/models/user_model.dart';
import '../models/question_model.dart';
import '../models/ticket_status.dart';
import '../services/question_service.dart';
import '../widgets/question_card.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

typedef SivitasTicketsScreen = MemberTicketsScreen;

class MemberTicketsScreen extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const MemberTicketsScreen({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<MemberTicketsScreen> createState() => _MemberTicketsScreenState();
}

class _MemberTicketsScreenState extends State<MemberTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<QuestionModel> _allQuestions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final questions = await QuestionService.getMyQuestions(
        userId: widget.user.id?.toString(),
        user: widget.user,
        token: widget.user.token,
      );
      if (mounted) {
        setState(() {
          _allQuestions = questions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allActiveTickets = _allQuestions.where((q) => q.isActive).toList();
    final openTickets = _allQuestions.where((q) => q.isActive && (q.ticketStatus == TicketStatus.open || q.ticketStatus == TicketStatus.offHoursQueue)).toList();
    final inProgressTickets = _allQuestions.where((q) => q.isActive && q.ticketStatus != TicketStatus.open && q.ticketStatus != TicketStatus.offHoursQueue).toList();
    final closedTickets = _allQuestions.where((q) => q.isClosed).toList();

    List<QuestionModel> filterBySearch(List<QuestionModel> list) {
      if (_searchQuery.isEmpty) return list;
      return list.where((q) {
        final matchTitle = q.judul.toLowerCase().contains(_searchQuery);
        final matchContent = q.isi.toLowerCase().contains(_searchQuery);
        final matchTicket = (q.ticketNumber ?? '').toLowerCase().contains(_searchQuery);
        final matchTeam = (q.targetTimPusat ?? q.targetTim ?? '').toLowerCase().contains(_searchQuery);
        final matchCat = q.displayCategory.toLowerCase().contains(_searchQuery);
        return matchTitle || matchContent || matchTicket || matchTeam || matchCat;
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tiket Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.colorText,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.colorSurface,
        foregroundColor: AppColors.colorText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.colorPrimary,
          unselectedLabelColor: AppColors.colorTextMuted,
          indicatorColor: AppColors.colorPrimary,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            _buildTabItem(label: 'Semua Aktif', count: allActiveTickets.length),
            _buildTabItem(label: 'Belum Ditangani', count: openTickets.length),
            _buildTabItem(label: 'Sedang Ditangani', count: inProgressTickets.length),
            _buildTabItem(label: 'Selesai', count: closedTickets.length),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SearchFilterBar(
                    hintText: 'Cari no tiket, judul, atau kata kunci...',
                    onSearchChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTicketListView(
                        tickets: filterBySearch(allActiveTickets),
                        emptyTitle: _searchQuery.isNotEmpty
                            ? 'Tiket tidak ditemukan'
                            : 'Tidak ada tiket aktif',
                        emptySubtitle: _searchQuery.isNotEmpty
                            ? 'Tidak ada tiket aktif yang sesuai dengan pencarian "$_searchQuery".'
                            : 'Semua pertanyaan Anda telah selesai dijawab atau belum diajukan.',
                        emptyIcon: _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.mark_chat_read_outlined,
                        showAskButton: _searchQuery.isEmpty,
                      ),
                      _buildTicketListView(
                        tickets: filterBySearch(openTickets),
                        emptyTitle: _searchQuery.isNotEmpty
                            ? 'Tiket tidak ditemukan'
                            : 'Tidak ada tiket belum ditangani',
                        emptySubtitle: _searchQuery.isNotEmpty
                            ? 'Tidak ada tiket baru yang sesuai dengan pencarian "$_searchQuery".'
                            : 'Semua tiket baru Anda telah mulai diproses oleh tim layanan.',
                        emptyIcon: _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.hourglass_empty_rounded,
                        showAskButton: false,
                      ),
                      _buildTicketListView(
                        tickets: filterBySearch(inProgressTickets),
                        emptyTitle: _searchQuery.isNotEmpty
                            ? 'Tiket tidak ditemukan'
                            : 'Tidak ada tiket sedang ditangani',
                        emptySubtitle: _searchQuery.isNotEmpty
                            ? 'Tidak ada tiket sedang ditangani yang sesuai dengan pencarian "$_searchQuery".'
                            : 'Belum ada tiket yang sedang diproses atau ditangani tim saat ini.',
                        emptyIcon: _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.support_agent_rounded,
                        showAskButton: false,
                      ),
                      _buildTicketListView(
                        tickets: filterBySearch(closedTickets),
                        emptyTitle: _searchQuery.isNotEmpty
                            ? 'Tiket tidak ditemukan'
                            : 'Belum ada tiket selesai',
                        emptySubtitle: _searchQuery.isNotEmpty
                            ? 'Tidak ada tiket selesai yang sesuai dengan pencarian "$_searchQuery".'
                            : 'Pertanyaan yang telah selesai dijawab oleh Tim BOSDM akan tersimpan di sini.',
                        emptyIcon: _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.task_alt_outlined,
                        showAskButton: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabItem({required String label, required int count}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (!_isLoading) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: count > 0 ? AppColors.colorPrimary.withValues(alpha: 0.12) : AppColors.slate200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: count > 0 ? AppColors.colorPrimary : AppColors.slate600,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTicketListView({
    required List<QuestionModel> tickets,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    required bool showAskButton,
  }) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, size: 48, color: AppColors.slate600),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: AppTypography.heading3.copyWith(color: AppColors.slate900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: AppTypography.bodySmall.copyWith(color: AppColors.slate600),
                textAlign: TextAlign.center,
              ),
              if (showAskButton) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
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
                    _loadTickets();
                  },
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: const Text('Ajukan Pertanyaan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: AppColors.colorPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final question = tickets[index];
              return QuestionCard(
                question: question,
                currentUser: widget.user,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionDetailScreen(
                        question: question.user == null ? question.copyWith(user: widget.user) : question,
                        currentUser: widget.user,
                      ),
                    ),
                  );
                  _loadTickets();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
