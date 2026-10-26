import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/export/excel_export_service.dart';
import '../../questions/models/question_model.dart';
import '../services/performance_analytics_service.dart';
import 'staff_performance_detail_screen.dart';

class StaffLeaderboardScreen extends StatefulWidget {
  final List<QuestionModel> questions;

  const StaffLeaderboardScreen({
    super.key,
    required this.questions,
  });

  @override
  State<StaffLeaderboardScreen> createState() => _StaffLeaderboardScreenState();
}

class _StaffLeaderboardScreenState extends State<StaffLeaderboardScreen> {
  bool _isLoading = false;
  bool _isDownloading = false;
  String _selectedTeam = 'Semua Tim';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<StaffPerformanceStat> _allStaffList = [];

  static const List<String> _teamFilters = [
    'Semua Tim',
    'LKSDM 1',
    'LKSDM 2',
    'LKSDM 3',
    'LKSDM 4',
    'LKSDM 5',
    'LKSDM 6',
    'LKSDM 7',
    'LKSDM 8',
    'Ortala',
    'Renbangkar',
    'Mutasi',
    'JF',
    'Renbangkom',
    'Penkom',
    'Mankin',
    'Bindis',
    'PDIS',
  ];

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
    setState(() => _isLoading = true);
    try {
      final list =
          await PerformanceAnalyticsService.fetchStaffLeaderboardFromSupabase(
        fallbackQuestions: widget.questions,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _allStaffList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allStaffList =
              PerformanceAnalyticsService.getStaffPerformanceLeaderboard(
            widget.questions,
            limit: 100,
          );
          _isLoading = false;
        });
      }
    }
  }

  List<StaffPerformanceStat> get _filteredStaffList {
    return _allStaffList.where((staff) {
      // 1. Filter Tim / Kawasan
      if (_selectedTeam != 'Semua Tim') {
        final filterClean = _selectedTeam.toLowerCase();
        final matchTeam =
            staff.teamOrLksdm.toLowerCase().contains(filterClean);
        final matchRole = staff.role.toLowerCase().contains(filterClean);
        if (!matchTeam && !matchRole) return false;
      }

      // 2. Filter Pencarian Nama / Peran
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchName = staff.name.toLowerCase().contains(q);
        final matchRole = staff.role.toLowerCase().contains(q);
        final matchTeam = staff.teamOrLksdm.toLowerCase().contains(q);
        if (!matchName && !matchRole && !matchTeam) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _downloadExcel() async {
    if (_isDownloading) return;
    final staffToExport = _filteredStaffList;
    if (staffToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data petugas untuk diunduh.'),
          backgroundColor: AppColors.slate700,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final filePath =
          await ExcelExportService.exportStaffLeaderboardToExcel(
        staffToExport,
        teamFilter: _selectedTeam,
      );

      if (!mounted) return;

      final fileName = filePath.split(RegExp(r'[\\/]')).last;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Laporan berhasil diunduh:\n$fileName',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'BUKA',
            textColor: const Color(0xFF5EEAD4),
            onPressed: () {
              ExcelExportService.openExportedFile(filePath);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat berkas Excel: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffList = _filteredStaffList;

    // Metrik agregat
    final totalStaff = staffList.length;
    final totalTickets = staffList.fold<int>(
        0, (sum, item) => sum + item.ticketsHandledCount);
    final avgCsat = staffList.isEmpty
        ? 0.0
        : staffList.fold<double>(
                0.0, (sum, item) => sum + item.averageRating) /
            staffList.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard Kinerja Petugas',
            style: AppTypography.heading3),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Download Laporan Excel (.xlsx)',
            onPressed: _isDownloading ? null : _downloadExcel,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.primaryRed,
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryRed,
        child: Column(
          children: [
            // 1. Search Box & Filter Chips
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama petugas atau peran...',
                      hintStyle: const TextStyle(
                          fontSize: 12.5, color: AppColors.slate400),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.slate400),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 18, color: AppColors.slate400),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: AppColors.slate50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Filter Chips
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _teamFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final team = _teamFilters[index];
                        final isSelected = _selectedTeam == team;

                        return ChoiceChip(
                          label: Text(team),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedTeam = team);
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : AppColors.slate700,
                          ),
                          selectedColor: AppColors.primaryRed,
                          backgroundColor: AppColors.slate100,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // 2. Summary Metric Bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    label: 'Petugas Aktif',
                    value: '$totalStaff',
                    icon: Icons.people_outline,
                    color: const Color(0xFF0284C7),
                  ),
                  Container(
                      width: 1, height: 24, color: AppColors.slate200),
                  _buildSummaryItem(
                    label: 'CSAT Rata-rata',
                    value: '${avgCsat.toStringAsFixed(1)} ★',
                    icon: Icons.star_outline_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  Container(
                      width: 1, height: 24, color: AppColors.slate200),
                  _buildSummaryItem(
                    label: 'Tiket Ditangani',
                    value: '$totalTickets',
                    icon: Icons.task_alt,
                    color: const Color(0xFF059669),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // 3. Ranked Staff List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryRed),
                    )
                  : staffList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search_outlined,
                                  size: 48, color: AppColors.slate400),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ada petugas cocok dengan "$_searchQuery"'
                                    : 'Belum ada data kinerja petugas.',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.slate500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: staffList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final staff = staffList[index];
                            final rank = index + 1;
                            return _buildStaffLeaderboardCard(staff, rank);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isDownloading ? null : _downloadExcel,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 0,
            ),
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(
              _isDownloading
                  ? 'Sedang Memproses Berkas...'
                  : 'Download Laporan Leaderboard (.xlsx)',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffLeaderboardCard(StaffPerformanceStat staff, int rank) {
    Color rankColor = const Color(0xFF64748B);
    Color rankBg = AppColors.slate100;
    Widget? medalIcon;

    if (rank == 1) {
      rankColor = const Color(0xFFD97706);
      rankBg = const Color(0xFFFEF3C7);
      medalIcon = const Icon(Icons.workspace_premium,
          size: 16, color: Color(0xFFD97706));
    } else if (rank == 2) {
      rankColor = const Color(0xFF475569);
      rankBg = const Color(0xFFF1F5F9);
      medalIcon = const Icon(Icons.military_tech,
          size: 16, color: Color(0xFF64748B));
    } else if (rank == 3) {
      rankColor = const Color(0xFFB45309);
      rankBg = const Color(0xFFFFEDD5);
      medalIcon = const Icon(Icons.military_tech,
          size: 16, color: Color(0xFFB45309));
    }

    final initial =
        staff.name.trim().isNotEmpty ? staff.name.trim()[0].toUpperCase() : 'P';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StaffPerformanceDetailScreen(
              staff: staff,
              allQuestions: widget.questions,
              rank: rank,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: rank <= 3 ? rankColor.withAlpha(80) : AppColors.border,
            width: rank <= 3 ? 1.2 : 1,
          ),
          boxShadow: [
            if (rank <= 3)
              BoxShadow(
                color: rankColor.withAlpha(20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Rank Number / Medal
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankBg,
                shape: BoxShape.circle,
                border: Border.all(color: rankColor.withAlpha(120), width: 1),
              ),
              child: medalIcon ??
                  Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
            ),
            const SizedBox(width: 10),

            // Staff Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryRed.withAlpha(20),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Staff Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          staff.role,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          staff.teamOrLksdm,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.slate500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Metrics Pills
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 2),
                    Text(
                      staff.averageRating > 0
                          ? staff.averageRating.toStringAsFixed(1)
                          : '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${staff.ticketsHandledCount} tiket',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),

            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
