import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/widgets/custom_fab.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

class LksdmConsultationTicketsScreen extends StatefulWidget {
  final UserModel user;

  const LksdmConsultationTicketsScreen({
    super.key,
    required this.user,
  });

  @override
  State<LksdmConsultationTicketsScreen> createState() =>
      _LksdmConsultationTicketsScreenState();
}

class _LksdmConsultationTicketsScreenState
    extends State<LksdmConsultationTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QuestionModel> _tickets = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final list = await QuestionService.getMyQuestions(
        userId: widget.user.id?.toString(),
        token: widget.user.token,
      );
      if (mounted) {
        setState(() {
          // Filter hanya tiket yang ditujukan langsung ke Pusat / tiket mandiri LKSDM
          _tickets = list.where((q) {
            return q.isMandiriLksdm ||
                (q.targetTimPusat != null && q.targetTimPusat!.isNotEmpty);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<QuestionModel> _getFilteredTickets(int tabIndex) {
    var result = _tickets;

    if (tabIndex == 1) {
      // Menunggu / Diproses Pusat
      result = result.where((q) => q.isActive).toList();
    } else if (tabIndex == 2) {
      // Selesai
      result = result.where((q) => q.isClosed).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((q) {
        final judul = q.judul.toLowerCase();
        final isi = q.isi.toLowerCase();
        final tim = (q.targetTimPusat ?? '').toLowerCase();
        final tkt = (q.ticketNumber ?? '').toLowerCase();
        return judul.contains(query) ||
            isi.contains(query) ||
            tim.contains(query) ||
            tkt.contains(query);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final lksdmName = widget.user.effectiveLksdm;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konsultasi Saya ke Pusat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
                color: AppColors.slate900,
              ),
            ),
            Text(
              'Daftar Tiket Konsultasi Staf/Ketua $lksdmName',
              style: const TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple.shade900,
          unselectedLabelColor: AppColors.slate500,
          indicatorColor: Colors.purple.shade800,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Diproses Pusat'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari judul, nomor tiket, atau tim pusat...',
                hintStyle:
                    const TextStyle(fontSize: 12, color: AppColors.slate400),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.slate100,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tab View Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTicketList(0),
                      _buildTicketList(1),
                      _buildTicketList(2),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: CustomFab(
        label: 'Konsultasi Baru',
        backgroundColor: Colors.purple.shade800,
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AskQuestionScreen(
                token: widget.user.token ?? '',
                user: widget.user,
                isLksdmConsultation: true,
              ),
            ),
          );
          if (res == true || mounted) {
            _loadTickets();
          }
        },
      ),
    );
  }

  Widget _buildTicketList(int tabIndex) {
    final tickets = _getFilteredTickets(tabIndex);

    if (tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTickets,
        color: Colors.purple,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.question_answer_outlined,
                  size: 48,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Belum Ada Tiket Konsultasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                tabIndex == 0
                    ? 'Anda belum pernah mengajukan tiket konsultasi teknis langsung ke tim pusat.'
                    : (tabIndex == 1
                        ? 'Tidak ada tiket konsultasi yang sedang aktif diproses kantor pusat.'
                        : 'Belum ada tiket konsultasi yang selesai.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Buat Konsultasi ke Pusat',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AskQuestionScreen(
                        token: widget.user.token ?? '',
                        user: widget.user,
                        isLksdmConsultation: true,
                      ),
                    ),
                  );
                  if (res == true || mounted) {
                    _loadTickets();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: Colors.purple,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final q = tickets[index];
          final tktNo = q.ticketNumber ?? '#${q.id}';
          final targetTeam = q.targetTimPusat ?? 'Tim Pusat BOSDM';

          return InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestionDetailScreen(
                    question: q.user == null ? q.copyWith(user: widget.user) : q,
                    currentUser: widget.user,
                  ),
                ),
              );
              _loadTickets();
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Header: Ticket No + Target Team + Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: Colors.purple.shade200,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          tktNo,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_right_alt_rounded,
                              size: 16,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                targetTeam,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(
                        status: q.status,
                        useShortLabel: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Judul
                  Text(
                    q.judul,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Uraian snippet
                  Text(
                    q.isi,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Footer: Tanggal + Balasan chat count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        q.formattedDate,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.slate400,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${q.answers?.length ?? 0} tanggapan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
