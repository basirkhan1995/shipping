part of 'acc_statement_bloc.dart';

sealed class AccStatementState extends Equatable {
  const AccStatementState();
}

final class AccStatementInitial extends AccStatementState {
  @override
  List<Object> get props => [];
}

final class AccStatementLoadingState extends AccStatementState {
  @override
  List<Object> get props => [];
}

final class AccStatementLoadedState extends AccStatementState {
  final AccountStatementModel accStatementDetails;
  const AccStatementLoadedState({required this.accStatementDetails});
  @override
  List<Object> get props => [accStatementDetails];
}

final class AccStatementErrorState extends AccStatementState {
  final String message;

  /// Non-null when the error is "the account's owner is locked".
  /// The view uses this to open the verify dialog.
  final int? perID;

  const AccStatementErrorState(this.message, {this.perID});

  @override
  List<Object?> get props => [message, perID];
}