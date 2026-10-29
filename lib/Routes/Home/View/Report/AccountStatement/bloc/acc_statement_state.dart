part of 'acc_statement_bloc.dart';

sealed class AccStatementState extends Equatable {
  const AccStatementState();
}

final class AccStatementInitial extends AccStatementState {
  @override
  List<Object> get props => [];
}

final class AccStatementLoadingState extends AccStatementState{
  @override
  List<Object> get props => [];
}

final class AccStatementLoadedState extends AccStatementState{
  final AccountStatementModel accStatementDetails;
  const AccStatementLoadedState({required this.accStatementDetails});
  @override
  List<Object> get props => [accStatementDetails];
}

final class AccStatementErrorState extends AccStatementState{
  final String message;
  const AccStatementErrorState(this.message);
  @override
  List<Object> get props => [message];
}