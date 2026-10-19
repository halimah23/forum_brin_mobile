import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../questions/data/lksdm_catalog_data.dart';
import '../../questions/data/tusi_catalog_data.dart';
import '../../questions/models/question_model.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/reopen_ticket_dialog.dart';
import '../widgets/audit_question_card.dart';

class SuperAdminAuditScreen extends StatefulWidget {
  final UserModel user;

  const SuperAdminAuditScreen({
    super.key,
    required this.user,
  });

  @override
  State<SuperAdminAuditScreen> createState() => _SuperAdminAuditScreenState();
}

class _SuperAdminAuditScreenState extends State<SuperAdminAuditScreen>
    with SingleTickerProviderStateMixin {
  List<QuestionModel> _allQuestions = [];
  bool _isLoading = true;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedLksdm = 'Semua LKSDM';
  String _selectedTimPusat = 'Semua Tim Pusat';
  String _selectedVisibility = 'semua'; // 'semua', 'privat', 'publik'

  final List<String> _statusFilters = [
    'semua',
    'menunggu_lksdm',
    'ditangani_lksdm',
    'dialihkan_ke_pusat',
    'selesai',
  ];

  final List<String> _tabLabels = [
    'Semua',
    'Antrean LKSDM',
    'Diproses',
    'Eskalasi Pusat',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final list = await QuestionService.getQuestions();
    if (mounted) {
      setState(() {
        _allQuestions = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReopenTicket(QuestionModel q) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ReopenTicketDialog.show(
      context,
      question: q,
      superAdminName: widget.user.name,
    );

    if (!mounted) return;

    if (success == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tiket berhasil dibuka kembali dan dialihkan penanganannya.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _loadQuestions();
    }
  }

  bool _isExceedingSla(QuestionModel q) {
    if (q.isClosed || q.createdAt == null) return false;
    try {
      final created = DateTime.parse(q.createdAt!);
      final diffHours = DateTime.now().difference(created).inHours;
      return diffHours >= 24 && (q.answers == null || q.answers!.isEmpty);
    } catch (_) {
      return false;
    }
  }

  List<QuestionModel> _getFilteredQuestions() {
    final currentStatus = _statusFilters[_tabController.index];

    return _allQuestions.where((q) {
      // 1. Status Filter
      if (currentStatus != 'semua') {
        if (currentStatus == 'menunggu_lksdm') {
          if (!['menunggu_lksdm', 'menunggu_disposisi', 'open', 'OPEN'].contains(q.status.toLowerCase())) {
            return false;
          }
        } else if (currentStatus == 'ditangani_lksdm') {
          if (!['ditangani_lksdm', 'sedang_diproses', 'in_progress', 'waiting_user'].contains(q.status.toLowerCase())) {
            return false;
          }
        } else if (currentStatus == 'dialihkan_ke_pusat') {
          if (!['dialihkan_ke_pusat', 'eskalasi_pusat', 'escalated', 'in_progress_center'].contains(q.status.toLowerCase())) {
            return false;
          }
        } else if (currentStatus == 'selesai') {
          if (!['selesai', 'closed', 'resolved', 'CLOSED', 'RESOLVED'].contains(q.status.toLowerCase())) {
            return false;
          }
        }
      }

      // 2. Visibility Filter
      if (_selectedVisibility == 'privat' && q.isPublic) return false;
      if (_selectedVisibility == 'publik' && !q.isPublic) return false;

      // 3. LKSDM Kawasan Filter
      if (_selectedLksdm != 'Semua LKSDM') {
        final lk = (q.lksdmKawasan ?? q.lksdmWilayah ?? '').toLowerCase();
        if (!lk.contains(_selectedLksdm.toLowerCase())) return false;
      }

      // 4. Tim Pusat Filter
      if (_selectedTimPusat != 'Semua Tim Pusat') {
        final tp = (q.targetTimPusat ?? q.targetTim ?? '').toLowerCase();
        if (!tp.contains(_selectedTimPusat.toLowerCase())) return false;
      }

      // 5. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final judul = q.judul.toLowerCase();
        final isi = q.isi.toLowerCase();
        final ticket = (q.ticketNumber ?? '').toLowerCase();
        final user = (q.user?.name ?? '').toLowerCase();
        if (!judul.contains(query) &&
            !isi.contains(query) &&
            !ticket.contains(query) &&
            !user.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final lksdmOptions = [
              'Semua LKSDM',
              ...LksdmCatalogData.allLksdm.map((e) => e.shortName),
            ];

            final timPusatOptions = [
              'Semua Tim Pusat',
              ...TusiCatalogData.centralTeams,
            ];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter Lanjutan Audit',
                            style: AppTypography.heading2,
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedLksdm = 'Semua LKSDM';
                                _selectedTimPusat = 'Semua Tim Pusat';
                                _selectedVisibility = 'semua';
                              });
                              setState(() {});
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      // Filter Visibilitas
                      const Text(
                        'Visibilitas Tiket',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChoiceChip('Semua', 'semua', _selectedVisibility, (v) {
                            setModalState(() => _selectedVisibility = v);
                            setState(() {});
                          }),
                          const SizedBox(width: 8),
                          _buildChoiceChip('Privat Saja', 'privat', _selectedVisibility, (v) {
                            setModalState(() => _selectedVisibility = v);
                            setState(() {});
                          }),
                          const SizedBox(width: 8),
                          _buildChoiceChip('Publik Saja', 'publik', _selectedVisibility, (v) {
                            setModalState(() => _selectedVisibility = v);
                            setState(() {});
                          }),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Filter Kawasan LKSDM
                      const Text(
                        'Wilayah Kawasan LKSDM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLksdm,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        isExpanded: true,
                        items: lksdmOptions.map((opt) {
                          return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _selectedLksdm = val);
                            setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      // Filter Tim Pusat
                      const Text(
                        'Tim Layanan Pusat (14 Tim)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTimPusat,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        isExpanded: true,
                        items: timPusatOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(
                              opt,
                              style: const TextStyle(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _selectedTimPusat = val);
                            setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF512DA8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Terapkan Filter Audit'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceChip(String label, String value, String current, Function(String) onSelect) {
    final bool isSelected = current == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.slate700)),
      selected: isSelected,
      selectedColor: const Color(0xFF512DA8),
      backgroundColor: AppColors.slate100,
      onSelected: (_) => onSelect(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _getFilteredQuestions();
    final totalCount = _allQuestions.length;
    final activeCount = _allQuestions.where((q) => q.isActive).length;
    final overSlaCount = _allQuestions.where(_isExceedingSla).length;
    final escalatedCount = _allQuestions.where((q) => q.isEscalated).length;

    final bool hasActiveFilter = _selectedLksdm != 'Semua LKSDM' ||
        _selectedTimPusat != 'Semua Tim Pusat' ||
        _selectedVisibility != 'semua';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Seluruh Tiket',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              'Pengawasan & Investigasi SLA Sistem',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Filter Lanjutan',
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded, color: Colors.white),
                if (hasActiveFilter)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadQuestions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: _tabLabels.map((lbl) => Tab(text: lbl)).toList(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // Audit Summary Quick Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFF512DA8).withAlpha(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quickAuditStat('Total', '$totalCount', AppColors.slate800),
                    _quickAuditStat('Aktif', '$activeCount', const Color(0xFF0284C7)),
                    _quickAuditStat('Eskalasi', '$escalatedCount', const Color(0xFFC2410C)),
                    _quickAuditStat('Lewat SLA', '$overSlaCount', AppColors.warning),
                  ],
                ),
              ),

              // Search Bar & Filter Indicators
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari nomor tiket, judul, atau pelapor...',
                        hintStyle: const TextStyle(fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.slate500),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    if (hasActiveFilter) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.filter_alt, size: 12, color: Color(0xFF512DA8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Filter: ${_selectedVisibility != "semua" ? "[${_selectedVisibility.toUpperCase()}] " : ""}$_selectedLksdm • $_selectedTimPusat',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF512DA8), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedLksdm = 'Semua LKSDM';
                                _selectedTimPusat = 'Semua Tim Pusat';
                                _selectedVisibility = 'semua';
                              });
                            },
                            child: const Text('Hapus Filter', style: TextStyle(fontSize: 11, color: AppColors.error)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Question List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF512DA8)))
                    : RefreshIndicator(
                        onRefresh: _loadQuestions,
                        color: const Color(0xFF512DA8),
                        child: filteredQuestions.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.assignment_turned_in_outlined, size: 54, color: Colors.grey.shade400),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Tidak ada tiket audit yang cocok.',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Ubah kata kunci pencarian atau reset filter audit.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filteredQuestions.length,
                                itemBuilder: (context, index) {
                                  final q = filteredQuestions[index];
                                  return AuditQuestionCard(
                                    question: q,
                                    onReopen: q.isClosed ? () => _handleReopenTicket(q) : null,
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
                                      _loadQuestions();
                                    },
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAuditStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.slate600),
        ),
      ],
    );
  }
}
