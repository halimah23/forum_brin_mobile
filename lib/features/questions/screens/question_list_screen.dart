import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' show ChatPlusIn;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/widgets/custom_fab.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../reports/services/report_export_service.dart';
import '../data/trending_issues_data.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../cubits/question_list_cubit.dart';
import '../cubits/question_list_state.dart';
import '../models/question_model.dart';
import '../widgets/question_card.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

class QuestionListScreen extends StatelessWidget {
  final UserModel user;
  final String? initialTeamFilter;
  final String? initialStatusFilter;
  final String? title;
  final bool? isPublicOnly;
  final bool? isPrivateOnly;

  const QuestionListScreen({
    super.key,
    required this.user,
    this.initialTeamFilter,
    this.initialStatusFilter,
    this.title,
    this.isPublicOnly,
    this.isPrivateOnly,
  });

  @override
  Widget build(BuildContext context) {
    final bool shouldFilterPublicOnly = isPublicOnly ?? (isPrivateOnly == true ? false : (initialTeamFilter == null && user.userRole == UserRole.member));

    return BlocProvider(
      create: (context) => QuestionListCubit()
        ..fetchQuestions(
          token: user.token ?? '',
          teamFilter: initialTeamFilter,
          statusFilter: initialStatusFilter,
          isPublicOnly: shouldFilterPublicOnly ? true : null,
          isPrivateOnly: isPrivateOnly,
        ),
      child: QuestionListView(
        user: user,
        initialTeamFilter: initialTeamFilter,
        initialStatusFilter: initialStatusFilter,
        title: title,
        isPublicOnly: shouldFilterPublicOnly ? true : null,
        isPrivateOnly: isPrivateOnly,
      ),
    );
  }
}

class QuestionListView extends StatefulWidget {
  final UserModel user;
  final String? initialTeamFilter;
  final String? initialStatusFilter;
  final String? title;
  final bool? isPublicOnly;
  final bool? isPrivateOnly;

  const QuestionListView({
    super.key,
    required this.user,
    this.initialTeamFilter,
    this.initialStatusFilter,
    this.title,
    this.isPublicOnly,
    this.isPrivateOnly,
  });

  @override
  State<QuestionListView> createState() => _QuestionListViewState();
}

class _QuestionListViewState extends State<QuestionListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final List<String> _statuses;
  late final List<String> _tabLabels;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final bool isLksdm = widget.user.isAdminLksdm;
    final bool isPusat = widget.user.isAdminPusat;

    if (isLksdm) {
      _statuses = ['semua', 'menunggu_lksdm', 'ditangani_lksdm', 'dialihkan_ke_pusat', 'selesai'];
      _tabLabels = ['Semua', 'Antrean LKSDM', 'Ditangani', 'Eskalasi Pusat', 'Selesai'];
    } else if (isPusat) {
      _statuses = ['semua', 'dialihkan_ke_pusat', 'ditangani_lksdm', 'selesai'];
      _tabLabels = ['Semua', 'Antrean Pusat', 'Aktif', 'Selesai'];
    } else {
      _statuses = ['semua', 'menunggu_lksdm', 'ditangani_lksdm', 'dialihkan_ke_pusat', 'selesai'];
      _tabLabels = ['Semua', 'Menunggu', 'Diproses', 'Eskalasi Pusat', 'Selesai'];
    }

    int initialIndex = 0;
    if (widget.initialStatusFilter != null) {
      final filter = widget.initialStatusFilter!;
      int idx = _statuses.indexOf(filter);
      if (idx == -1) {
        if (filter == 'menunggu_disposisi') idx = _statuses.indexOf('menunggu_lksdm');
        if (filter == 'sedang_diproses') idx = _statuses.indexOf('ditangani_lksdm');
        if (filter == 'eskalasi_pusat') idx = _statuses.indexOf('dialihkan_ke_pusat');
      }
      if (idx != -1) initialIndex = idx;
    }
    _tabController = TabController(length: _statuses.length, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final selectedStatus = _statuses[_tabController.index];
      context.read<QuestionListCubit>().fetchQuestions(
            token: widget.user.token ?? '',
            teamFilter: widget.initialTeamFilter,
            statusFilter: selectedStatus,
            isPublicOnly: widget.isPublicOnly,
            isPrivateOnly: widget.isPrivateOnly,
          );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKetuaTim = widget.user.userRole == UserRole.ketuaTim;
    final headerTitle = widget.title ?? (isKetuaTim && widget.initialTeamFilter != null
        ? 'Antrean ${widget.initialTeamFilter}'
        : 'Antrean Tiket Pertanyaan');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(
          headerTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.user.userRole != UserRole.member)
            BlocBuilder<QuestionListCubit, QuestionListState>(
              builder: (context, state) {
                final list = state is QuestionListLoaded
                    ? state.questions
                    : <QuestionModel>[];
                return IconButton(
                  tooltip: 'Ekspor Rekap Laporan (CSV)',
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  onPressed: list.isEmpty
                      ? null
                      : () => _showExportReportDialog(context, list),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _tabLabels.map((lbl) => Tab(text: lbl)).toList(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
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
                child: BlocConsumer<QuestionListCubit, QuestionListState>(
                  listener: (context, state) {
                    if (state is QuestionListError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is QuestionListLoading || state is QuestionListInitial) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryRed),
                      );
                    }

                    if (state is QuestionListLoaded) {
                      final bool isForum = widget.isPublicOnly == true ||
                          (widget.user.userRole == UserRole.member &&
                              widget.initialTeamFilter == null);

                      final allQuestions = state.questions;
                      final filteredQuestions = allQuestions.where((q) {
                        if (_searchQuery.isEmpty) return true;
                        final matchTitle =
                            q.judul.toLowerCase().contains(_searchQuery);
                        final matchContent =
                            q.isi.toLowerCase().contains(_searchQuery);
                        final matchTicket = (q.ticketNumber ?? '')
                            .toLowerCase()
                            .contains(_searchQuery);
                        final matchAuthor = (q.user?.name ?? '')
                            .toLowerCase()
                            .contains(_searchQuery);
                        final matchTeam = (q.targetTim ?? '')
                            .toLowerCase()
                            .contains(_searchQuery);
                        return matchTitle ||
                            matchContent ||
                            matchTicket ||
                            matchAuthor ||
                            matchTeam;
                      }).toList();

                      if (filteredQuestions.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            final selectedStatus = _statuses[_tabController.index];
                            await context.read<QuestionListCubit>().fetchQuestions(
                                  token: widget.user.token ?? '',
                                  teamFilter: widget.initialTeamFilter,
                                  statusFilter: selectedStatus,
                                  isPublicOnly: widget.isPublicOnly,
                                );
                          },
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 32, horizontal: 16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off_rounded
                                          : (isForum
                                              ? Icons.forum_outlined
                                              : Icons.inbox_outlined),
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Tiket Tidak Ditemukan'
                                          : (isForum
                                              ? 'Belum Ada Diskusi Publik'
                                              : 'Tidak ada tiket dalam antrean ini.'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Tidak ada tiket yang sesuai dengan kata kunci "$_searchQuery".'
                                          : (isForum
                                              ? 'Pertanyaan dan materi kepegawaian publik resmi dari BOSDM akan tampil di sini.'
                                              : (widget.initialTeamFilter != null
                                                  ? 'Belum ada pertanyaan yang masuk untuk ${widget.initialTeamFilter}.'
                                                  : 'Silakan ajukan pertanyaan baru melalui tombol + di bawah.')),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              if (isForum) _buildCompactTrendingSection(context),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          final selectedStatus = _statuses[_tabController.index];
                          await context.read<QuestionListCubit>().fetchQuestions(
                                token: widget.user.token ?? '',
                                teamFilter: widget.initialTeamFilter,
                                statusFilter: selectedStatus,
                                isPublicOnly: widget.isPublicOnly,
                              );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredQuestions.length + (isForum ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (isForum && index == filteredQuestions.length) {
                              return _buildCompactTrendingSection(context);
                            }

                            final question = filteredQuestions[index];
                            return QuestionCard(
                              question: question,
                              currentUser: widget.user,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuestionDetailScreen(
                                      question: question,
                                      currentUser: widget.user,
                                    ),
                                  ),
                                );

                                if (context.mounted) {
                                  final selectedStatus =
                                      _statuses[_tabController.index];
                                  context.read<QuestionListCubit>().fetchQuestions(
                                        token: widget.user.token ?? '',
                                        teamFilter: widget.initialTeamFilter,
                                        statusFilter: selectedStatus,
                                        isPublicOnly: widget.isPublicOnly,
                                      );
                                }
                              },
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (widget.user.isSuperAdmin || widget.user.isEksekutif)
          ? null
          : CustomFab(
              label: 'Buat Tiket',
              icon: const ChatPlusIn(color: Colors.white, width: 20, height: 20),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AskQuestionScreen(token: widget.user.token ?? ''),
                  ),
                );

                if (!context.mounted) return;
                final selectedStatus = _statuses[_tabController.index];
                context.read<QuestionListCubit>().fetchQuestions(
                      token: widget.user.token ?? '',
                      teamFilter: widget.initialTeamFilter,
                      statusFilter: selectedStatus,
                      isPublicOnly: widget.isPublicOnly,
                    );
              },
            ),
    );
  }

  Widget _buildCompactTrendingSection(BuildContext context) {
    const issues = TrendingIssuesData.defaultTrendingIssues;
    final topThree = issues.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topik Populer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Isu kepegawaian paling sering ditanyakan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topThree.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 16, color: AppColors.border),
            itemBuilder: (context, index) {
              final item = topThree[index];
              final rankStr = (index + 1).toString().padLeft(2, '0');

              return Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 0 ? AppColors.primaryRed : AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      rankStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: index == 0 ? Colors.white : AppColors.slate700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: Text(
                      '${item.count} Tiket',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAllTrendingTopicsModal(context),
              icon: const Icon(Icons.format_list_bulleted_rounded, size: 16),
              label: const Text('Lihat Selengkapnya'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllTrendingTopicsModal(BuildContext context) {
    const issues = TrendingIssuesData.defaultTrendingIssues;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.primaryRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seluruh Topik Populer BOSDM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            'Rekapitulasi pertanyaan dan isu kepegawaian',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.slate600),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: issues.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 20, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = issues[index];
                    final rankStr = (index + 1).toString().padLeft(2, '0');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index < 3 ? AppColors.primaryRed : AppColors.slate100,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                rankStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: index < 3 ? Colors.white : AppColors.slate700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.slate100,
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: Text(
                                          'Kategori: ${item.category}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.slate700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: Text(
                                          'Tim: ${item.suggestedCentralTeam}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF1D4ED8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border:
                                    Border.all(color: AppColors.slate300, width: 1),
                              ),
                              child: Text(
                                '${item.count}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportReportDialog(
      BuildContext context, List<QuestionModel> questions) {
    final summary = ReportExportService.calculateSummary(questions);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.primaryRed),
            SizedBox(width: 8),
            Text('Ekspor Rekap Laporan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan data tiket untuk periode ini:',
              style: TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Tiket', '${summary['totalTickets']}'),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                      'Tiket Selesai', '${summary['closedTickets']}'),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Tingkat Kepatuhan SLA',
                      '${(summary['slaComplianceRate'] as double).toStringAsFixed(1)}%'),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Skor Rata-rata CSAT',
                      '${(summary['averageCsat'] as double).toStringAsFixed(1)} / 5.0'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Format berkas CSV kompatibel dengan Microsoft Excel dan Google Sheets.',
              style: TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Unduh CSV'),
            onPressed: () {
              Navigator.pop(ctx);
              ReportExportService.generateTicketsCsv(questions);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Laporan CSV berhasil di-generate (${questions.length} baris data).'),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900)),
      ],
    );
  }
}
