import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../auth/models/user_model.dart';
import '../models/question_model.dart';
import '../widgets/forum_discussion_card.dart';
import '../widgets/publish_and_standardize_dialog.dart';
import 'faq_screen.dart';
import 'question_detail_screen.dart';
import '../services/question_service.dart';

class SuperAdminForumScreen extends StatefulWidget {
  final UserModel user;

  const SuperAdminForumScreen({
    super.key,
    required this.user,
  });

  @override
  State<SuperAdminForumScreen> createState() => _SuperAdminForumScreenState();
}

class _SuperAdminForumScreenState extends State<SuperAdminForumScreen>
    with SingleTickerProviderStateMixin {
  List<QuestionModel> _publicQuestions = [];
  bool _isLoading = true;
  int? _processingPinQuestionId;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua Kategori';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadPublicQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicQuestions() async {
    setState(() => _isLoading = true);
    final list = await QuestionService.getQuestions(isPublicOnly: true);
    if (mounted) {
      setState(() {
        _publicQuestions = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTogglePin(QuestionModel q) async {
    if (q.id == null) return;
    final targetPin = !q.isPinned;

    // Jika ingin disematkan sebagai FAQ Tren namun belum dibakukan,
    // arahkan Superadmin untuk menelaah/membakukan struktur pertanyaan
    if (targetPin && !q.isStandardized) {
      final messenger = ScaffoldMessenger.of(context);
      final updated = await PublishAndStandardizeDialog.show(context, q);
      if (updated != null && mounted) {
        setState(() {
          final idx = _publicQuestions.indexWhere((item) => item.id == q.id);
          if (idx != -1) {
            _publicQuestions[idx] = updated;
          }
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('⭐ Pertanyaan berhasil dibakukan dan disematkan sebagai FAQ Tren!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        return;
      }
      return;
    }

    setState(() => _processingPinQuestionId = q.id);
    final messenger = ScaffoldMessenger.of(context);

    final success = await QuestionService.togglePinQuestion(
      questionId: q.id!,
      isPinned: targetPin,
    );

    if (mounted) {
      setState(() {
        _processingPinQuestionId = null;
        if (success) {
          final idx = _publicQuestions.indexWhere((item) => item.id == q.id);
          if (idx != -1) {
            _publicQuestions[idx] = q.copyWith(isPinned: targetPin);
          }
        }
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            targetPin
                ? '⭐ Topik berhasil disematkan sebagai FAQ Tren!'
                : 'Penyematan FAQ Tren dilepas.',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: targetPin ? Colors.amber.shade900 : AppColors.slate800,
        ),
      );
    }
  }

  List<String> _extractCategories() {
    final Set<String> categories = {'Semua Kategori'};
    for (final q in _publicQuestions) {
      final name = q.tugasFungsiNama ??
          ((q.tugasFungsi != null && q.tugasFungsi!.isNotEmpty)
              ? (q.tugasFungsi!.first.teamName ?? q.tugasFungsi!.first.nama)
              : null);
      if (name != null && name.isNotEmpty) {
        categories.add(name);
      }
    }
    return categories.toList();
  }

  List<QuestionModel> _getFilteredQuestions() {
    final isPinnedTab = _tabController.index == 1;

    return _publicQuestions.where((q) {
      // 1. Tab Pinned vs Semua
      if (isPinnedTab && !q.isPinned) return false;

      // 2. Kategori Filter
      if (_selectedCategory != 'Semua Kategori') {
        final name = q.tugasFungsiNama ??
            ((q.tugasFungsi != null && q.tugasFungsi!.isNotEmpty)
                ? (q.tugasFungsi!.first.teamName ?? q.tugasFungsi!.first.nama)
                : '');
        if (name != _selectedCategory) return false;
      }

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final judul = q.judul.toLowerCase();
        final isi = q.isi.toLowerCase();
        final author = (q.user?.name ?? '').toLowerCase();
        if (!judul.contains(query) && !isi.contains(query) && !author.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredQuestions();
    final categories = _extractCategories();
    final pinnedCount = _publicQuestions.where((q) => q.isPinned).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forum Kepegawaian BRIN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              'Ruang Diskusi & Kurasi Konten Publik',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bank FAQ Resmi',
            icon: const Icon(Icons.quiz_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadPublicQuestions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Semua Diskusi (${_publicQuestions.length})'),
            Tab(text: '⭐ Topik Tren / FAQ ($pinnedCount)'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // Search & Category Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari topik diskusi atau kata kunci kepegawaian...',
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
                    if (categories.length > 2) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final cat = categories[idx];
                            final isSel = cat == _selectedCategory;
                            return ChoiceChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSel ? Colors.white : AppColors.slate700,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primaryRed,
                              backgroundColor: AppColors.slate100,
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Forum List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                    : RefreshIndicator(
                        onRefresh: _loadPublicQuestions,
                        color: AppColors.primaryRed,
                        child: filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.forum_outlined, size: 54, color: Colors.grey.shade400),
                                          const SizedBox(height: 10),
                                          Text(
                                            _tabController.index == 1
                                                ? 'Belum ada topik yang disematkan sebagai FAQ.'
                                                : 'Tidak ada diskusi publik yang cocok.',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _tabController.index == 1
                                                ? 'Tekan ikon jarum semat di kartu forum untuk menjadikannya FAQ Tren.'
                                                : 'Coba ubah kata kunci pencarian.',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final q = filtered[index];
                                  return ForumDiscussionCard(
                                    question: q,
                                    currentUser: widget.user,
                                    isProcessingPin: _processingPinQuestionId == q.id,
                                    onTogglePin: () => _handleTogglePin(q),
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
                                      _loadPublicQuestions();
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
}
