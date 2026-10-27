import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../auth/models/user_model.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import '../widgets/question_card.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

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
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
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
    final activeTickets = _allQuestions.where((q) => q.isActive).toList();
    final closedTickets = _allQuestions.where((q) => q.isClosed).toList();

    final filteredActiveTickets = activeTickets.where((q) {
      if (_searchQuery.isEmpty) return true;
      final matchTitle = q.judul.toLowerCase().contains(_searchQuery);
      final matchContent = q.isi.toLowerCase().contains(_searchQuery);
      final matchTicket = (q.ticketNumber ?? '').toLowerCase().contains(_searchQuery);
      final matchTeam = (q.targetTim ?? '').toLowerCase().contains(_searchQuery);
      return matchTitle || matchContent || matchTicket || matchTeam;
    }).toList();

    final filteredClosedTickets = closedTickets.where((q) {
      if (_searchQuery.isEmpty) return true;
      final matchTitle = q.judul.toLowerCase().contains(_searchQuery);
      final matchContent = q.isi.toLowerCase().contains(_searchQuery);
      final matchTicket = (q.ticketNumber ?? '').toLowerCase().contains(_searchQuery);
      final matchTeam = (q.targetTim ?? '').toLowerCase().contains(_searchQuery);
      return matchTitle || matchContent || matchTicket || matchTeam;
    }).toList();

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
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tiket Aktif'),
                  if (!_isLoading && activeTickets.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeTickets.length}',
                        style: const TextStyle(
                          color: AppColors.colorPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tiket Selesai'),
                  if (!_isLoading && closedTickets.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${closedTickets.length}',
                        style: const TextStyle(
                          color: AppColors.colorSecondaryStrong,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
                        tickets: filteredActiveTickets,
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
                        tickets: filteredClosedTickets,
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
