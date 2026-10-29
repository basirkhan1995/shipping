part of 'acc_statement_bloc.dart';

sealed class AccStatementEvent extends Equatable {
  const AccStatementEvent();
}

class LoadAccountStatementEvent extends AccStatementEvent{
  final int accountNumber;
  final String fromDate;
  final String toDate;
  const LoadAccountStatementEvent({required this.accountNumber, required this.fromDate, required this.toDate});

  @override
  List<Object?> get props => [accountNumber, fromDate, toDate];
}

class ResetAccStmtEvent extends AccStatementEvent{
  @override

  List<Object?> get props => [];
}