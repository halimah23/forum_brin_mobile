import 'package:equatable/equatable.dart';
import '../models/question_model.dart';

abstract class QuestionListState extends Equatable {
  const QuestionListState();

  @override
  List<Object?> get props => [];
}

class QuestionListInitial extends QuestionListState {}

class QuestionListLoading extends QuestionListState {}

class QuestionListLoaded extends QuestionListState {
  final List<QuestionModel> questions;

  const QuestionListLoaded(this.questions);

  @override
  List<Object?> get props => [questions];
}

class QuestionListError extends QuestionListState {
  final String message;

  const QuestionListError(this.message);

  @override
  List<Object?> get props => [message];
}
