import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' show ChatPlusIn;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/widgets/custom_fab.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../reports/services/report_export_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../cubits/question_list_cubit.dart';
import '../cubits/question_list_state.dart';
import '../data/service_category_catalog.dart';
import '../models/question_model.dart';
import '../widgets/question_card.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

class QuestionListScreen extends StatelessWidget {
  final UserModel user;
  final String? initialTeamFilter;
  final String? initialStatusFilter;
  final String? title;

  const QuestionListScreen({
    super.key,
    required this.user,
    this.initialTeamFilter,
    this.initialStatusFilter,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionListCubit()
        ..fetchQuestions(
          token: user.token ?? '',
          teamFilter: initialTeamFilter,
          statusFilter: initialStatusFilter,
        ),
      child: QuestionListView(
        user: user,
        initialTeamFilter: initialTeamFilter,
        initialStatusFilter: initialStatusFilter,
        title: title,
      ),
    );
  }
}

class QuestionListView extends StatefulWidget {
  final UserModel user;
  final String? initialTeamFilter;
  final String? initialStatusFilter;
  final String? title;

  const QuestionListView({
    super.key,
    required this.user,
    this.initialTeamFilter,
    this.initialStatusFilter,
    this.title,
  });

  @override
  State<QuestionListView> createState() => _QuestionListViewState();
}

class _QuestionListViewState extends State<QuestionListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final List<String> _statuses;
  late final List<String> _tabLabels;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'all';

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
      backgroundColor: AppColors.colorBg,
      appBar: AppBar(
        title: Text(
          headerTitle,
          style: const TextStyle(
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
        actions: [
          if (widget.user.userRole != UserRole.member)
            BlocBuilder<QuestionListCubit, QuestionListState>(
              builder: (context, state) {
                final list = state is QuestionListLoaded
                    ? state.questions
                    : <QuestionModel>[];
                return IconButton(
                  tooltip: 'Ekspor Rekap Laporan (CSV)',
                  icon: const Icon(Icons.download_rounded, color: AppColors.colorText),
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
          labelColor: AppColors.colorPrimary,
          unselectedLabelColor: AppColors.colorTextMuted,
          indicatorColor: AppColors.colorPrimary,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SearchFilterBar(
                  hintText: 'Cari no tiket, judul, atau kata kunci...',
                  onSearchChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              // Category Filter Chip Row (Semua, Kehadiran, Mutasi Unit, dsb)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                        child: CircularProgressIndicator(color: AppColors.colorPrimary),
                      );
                    }

                    if (state is QuestionListLoaded) {
                      final allQuestions = state.questions;
                      final filteredQuestions = allQuestions.where((q) {
                        if (_selectedCategoryFilter != 'all') {
                          if (!q.displayCategory
                              .toLowerCase()
                              .contains(_selectedCategoryFilter.toLowerCase())) {
                            return false;
                          }
                        }
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
                                          : Icons.inbox_outlined,
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Tiket Tidak Ditemukan'
                                          : 'Tidak Ada Tiket Layanan',
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
                                          : (widget.initialTeamFilter != null
                                              ? 'Belum ada tiket yang masuk untuk ${widget.initialTeamFilter}.'
                                              : 'Tidak ada tiket dalam antrean ini.'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
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
                              );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredQuestions.length,
                          itemBuilder: (context, index) {
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
                    builder: (context) => AskQuestionScreen(
                      token: widget.user.token ?? '',
                      user: widget.user,
                    ),
                  ),
                );

                if (!context.mounted) return;
                final selectedStatus = _statuses[_tabController.index];
                context.read<QuestionListCubit>().fetchQuestions(
                      token: widget.user.token ?? '',
                      teamFilter: widget.initialTeamFilter,
                      statusFilter: selectedStatus,
                    );
              },
            ),
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
            Icon(Icons.description_outlined, color: AppColors.colorPrimary),
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
              backgroundColor: AppColors.colorPrimary,
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

  Widget _buildCategoryFilterChip({
    required String id,
    required String label,
  }) {
    final isSelected = _selectedCategoryFilter == id;
    return InkWell(
      key: ValueKey('list_category_filter_$id'),
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
          color: isSelected ? AppColors.colorPrimary : AppColors.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.colorPrimary : AppColors.colorBorder,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 11,
              color: isSelected ? Colors.white : AppColors.colorTextMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.colorText,
              ),
            ),
          ],
        ),
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
