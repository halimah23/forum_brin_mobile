import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../cubits/question_list_cubit.dart';
import '../cubits/question_list_state.dart';
import '../models/question_model.dart';
import '../widgets/question_card.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

class MyQuestionsScreen extends StatelessWidget {
  final UserModel user;

  const MyQuestionsScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionListCubit()
        ..fetchQuestions(
          token: user.token ?? '',
        ),
      child: MyQuestionsView(user: user),
    );
  }
}

class MyQuestionsView extends StatefulWidget {
  final UserModel user;

  const MyQuestionsView({
    super.key,
    required this.user,
  });

  @override
  State<MyQuestionsView> createState() => _MyQuestionsViewState();
}

class _MyQuestionsViewState extends State<MyQuestionsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['semua', 'menunggu_disposisi', 'sedang_diproses', 'selesai'];
  final List<String> _tabLabels = ['Semua', 'Menunggu', 'Diproses', 'Selesai Dijawab'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final selectedStatus = _statuses[_tabController.index];
      context.read<QuestionListCubit>().fetchQuestions(
            token: widget.user.token ?? '',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Tiket & Pertanyaan Saya',
          style: TextStyle(
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
                          Icon(Icons.mark_chat_unread_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          const Text(
                            'Belum Ada Pertanyaan di Kategori Ini',
                            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajukan pertanyaan Anda mengenai kenaikan pangkat, Tusi, atau layanan kepegawaian lainnya.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _navigateToNewQuestion(context),
                            icon: const Icon(Icons.add_comment_outlined, size: 18),
                            label: const Text('Buat Tiket Baru'),
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
                          statusFilter: selectedStatus,
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.questions.length,
                    itemBuilder: (context, index) {
                      final QuestionModel question = state.questions[index];
                      final bool isAnswered = question.status.toLowerCase() == 'selesai' ||
                          (question.answers != null && question.answers!.isNotEmpty);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAnswered)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade300, width: 0.6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 14, color: Colors.green.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Telah Dijawab oleh Tim BOSDM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          QuestionCard(
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
                                      statusFilter: selectedStatus,
                                    );
                              }
                            },
                          ),
                        ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        onPressed: () => _navigateToNewQuestion(context),
        icon: const Icon(Icons.add),
        label: const Text('Topik Lain (Tiket Baru)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _navigateToNewQuestion(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AskQuestionScreen(token: widget.user.token ?? ''),
      ),
    );

    if (context.mounted) {
      final selectedStatus = _statuses[_tabController.index];
      context.read<QuestionListCubit>().fetchQuestions(
            token: widget.user.token ?? '',
            statusFilter: selectedStatus,
          );
    }
  }
}
