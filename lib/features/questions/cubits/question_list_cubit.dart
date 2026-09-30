import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/question_service.dart';
import 'question_list_state.dart';

class QuestionListCubit extends Cubit<QuestionListState> {
  QuestionListCubit() : super(QuestionListInitial());

  Future<void> fetchQuestions({
    String? token,
    String? teamFilter,
    String? statusFilter,
    String? userIdFilter,
    bool? isPublicOnly,
    bool? isPrivateOnly,
  }) async {
    emit(QuestionListLoading());
    try {
      final questions = await QuestionService.getQuestions(
        token: token,
        teamFilter: teamFilter,
        statusFilter: statusFilter,
        userIdFilter: userIdFilter,
        isPublicOnly: isPublicOnly,
        isPrivateOnly: isPrivateOnly,
      );
      emit(QuestionListLoaded(questions));
    } catch (e) {
      emit(QuestionListError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
