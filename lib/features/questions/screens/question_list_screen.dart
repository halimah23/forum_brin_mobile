import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../cubits/question_list_cubit.dart';
import '../cubits/question_list_state.dart';
import '../widgets/question_card.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

class QuestionListScreen extends StatelessWidget {
  final UserModel user;

  const QuestionListScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionListCubit()..fetchQuestions(user.token ?? ''),
      child: const QuestionListView(),
    );
  }
}

class QuestionListView extends StatelessWidget {
  const QuestionListView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.findAncestorWidgetOfExactType<QuestionListScreen>()!.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Tanya Jawab',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.accentBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
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
                  return const Center(
                    child: Text(
                      'Belum ada pertanyaan.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<QuestionListCubit>().fetchQuestions(user.token ?? ''),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.questions.length,
                    itemBuilder: (context, index) {
                      final question = state.questions[index];
                      return QuestionCard(
                        question: question,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionDetailScreen(question: question),
                            ),
                          );
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AskQuestionScreen(token: user.token ?? ''),
            ),
          );

          if (!context.mounted) return;
          context.read<QuestionListCubit>().fetchQuestions(user.token ?? '');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
