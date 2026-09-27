import 'package:equatable/equatable.dart';

abstract class AskQuestionState extends Equatable {
  const AskQuestionState();

  @override
  List<Object?> get props => [];
}

class AskQuestionInitial extends AskQuestionState {}

class AskQuestionSubmitting extends AskQuestionState {}

class AskQuestionSuccess extends AskQuestionState {}

class AskQuestionError extends AskQuestionState {
  final String message;

  const AskQuestionError(this.message);

  @override
  List<Object?> get props => [message];
}
