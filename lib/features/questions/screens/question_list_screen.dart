import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' show ChatPlusIn;

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_fab.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../cubits/question_list_cubit.dart';
import '../cubits/question_list_state.dart';
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
                if (state.questions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada tiket dalam antrean ini.',
                            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.initialTeamFilter != null
                                ? 'Belum ada pertanyaan yang masuk untuk ${widget.initialTeamFilter}.'
                                : 'Silakan ajukan pertanyaan baru melalui tombol + di bawah.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
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
                    itemCount: state.questions.length,
                    itemBuilder: (context, index) {
                      final question = state.questions[index];
                      return QuestionCard(
                        question: question,
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
                            final selectedStatus = _statuses[_tabController.index];
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
      ),
      floatingActionButton: CustomFab(
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
}
