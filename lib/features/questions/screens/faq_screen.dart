import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import 'faq_detail_screen.dart';

class FaqScreen extends StatefulWidget {
  final UserModel? currentUser;

  const FaqScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QuestionModel> _faqs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Mutasi & Promosi',
    'Kinerja & Disiplin',
    'Pengembangan Pegawai',
    'Gaji & Tunjangan',
    'Cuti & Kehadiran',
    'LKSDM Kawasan',
  ];

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() => _isLoading = true);
    final results = await QuestionService.getFaqQuestions();
    if (mounted) {
      setState(() {
        _faqs = results;
        _isLoading = false;
      });
    }
  }

  List<QuestionModel> get _filteredFaqs {
    return _faqs.where((faq) {
      // 1. Filter Kategori
      if (_selectedCategory != 'Semua') {
        final categoryLower = _selectedCategory.toLowerCase();
        final team = '${faq.effectiveTargetTim} ${faq.tugasFungsiNama ?? ''}'.toLowerCase();
        if (!team.contains(categoryLower)) {
          return false;
        }
      }

      // 2. Filter Pencarian
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = faq.judul.toLowerCase();
        final body = faq.isi.toLowerCase();
        final summary = (faq.summaryJawaban ?? faq.effectiveOfficialSummary).toLowerCase();
        final team = faq.effectiveTargetTim.toLowerCase();
        return title.contains(query) || body.contains(query) || summary.contains(query) || team.contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pertanyaan Populer & FAQ', style: AppTypography.heading3),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFaqs,
        color: AppColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Cari prosedur kepegawaian / topik FAQ...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate500),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                  const SizedBox(height: 12),

                  // Kategori Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.slate700,
                              ),
                            ),
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primaryRed,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryRed : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar FAQ Terverifikasi (${displayedList.length})',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.slate800),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'Resmi BOSDM',
                            style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Content List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
                    )
                  else if (displayedList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 44, color: AppColors.slate400),
                          SizedBox(height: 10),
                          Text(
                            'Tidak ada pertanyaan FAQ yang cocok.',
                            style: TextStyle(color: AppColors.slate800, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Coba gunakan kata kunci lain atau pilih kategori Semua.',
                            style: TextStyle(color: AppColors.slate500, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedList.length,
                      itemBuilder: (context, index) {
                        final faq = displayedList[index];
                        final summarySnippet = faq.hasSummary
                            ? faq.summaryJawaban!
                            : faq.effectiveOfficialSummary;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FaqDetailScreen(
                                    question: faq,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                              _loadFaqs();
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Item: Kategori Tag & Status
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryRed.withAlpha(20),
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: Text(
                                          faq.tugasFungsiNama ?? faq.effectiveTargetTim,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (faq.isPinned)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.push_pin, size: 10, color: Color(0xFFD97706)),
                                              SizedBox(width: 3),
                                              Text(
                                                'Utama',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 20,
                                        color: AppColors.slate400,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Judul Baku
                                  Text(
                                    faq.judul,
                                    style: AppTypography.heading3.copyWith(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slate900,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Cuplikan Rangkuman Solusi
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(color: const Color(0xFFDCFCE7)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 15,
                                          color: Color(0xFF16A34A),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            summarySnippet,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF166534),
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
