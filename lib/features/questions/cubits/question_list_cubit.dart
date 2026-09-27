import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/question_service.dart';
import 'question_list_state.dart';

class QuestionListCubit extends Cubit<QuestionListState> {
  QuestionListCubit() : super(QuestionListInitial());

  Future<void> fetchQuestions(String token) async {
    emit(QuestionListLoading());
    try {
      final questions = await QuestionService.getQuestions(token: token);
      emit(QuestionListLoaded(questions));
    } catch (e) {
      emit(QuestionListError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
