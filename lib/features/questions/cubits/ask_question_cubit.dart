import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/question_service.dart';
import 'ask_question_state.dart';

class AskQuestionCubit extends Cubit<AskQuestionState> {
  AskQuestionCubit() : super(AskQuestionInitial());

  Future<void> submitQuestion({
    required String token,
    required String judul,
    required String isi,
    required List<int> tugasFungsiIds,
    String? selectedTeam,
    String? lksdmKawasan,
    String? targetTimPusat,
    bool isPublic = true,
  }) async {
    emit(AskQuestionSubmitting());
    try {
      await QuestionService.createQuestion(
        token: token,
        judul: judul,
        isi: isi,
        tugasFungsiIds: tugasFungsiIds,
        selectedTeam: selectedTeam,
        lksdmKawasan: lksdmKawasan,
        targetTimPusat: targetTimPusat,
        isPublic: isPublic,
      );
      emit(AskQuestionSuccess());
    } catch (e) {
      emit(AskQuestionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
