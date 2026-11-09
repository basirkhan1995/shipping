part of 'acc_statement_bloc.dart';

sealed class AccStatementEvent extends Equatable {
  const AccStatementEvent();
}

class LoadAccountStatementEvent extends AccStatementEvent {
  final int accountNumber;
  final String fromDate;
  final String toDate;

  /// When true, tells the server the caller has already verified an
  /// admin for this account's owner. Skipped when the owner isn't locked.
  final bool unlock;

  const LoadAccountStatementEvent({
    required this.accountNumber,
    required this.fromDate,
    required this.toDate,
    this.unlock = false,
  });

  @override
  List<Object?> get props => [accountNumber, fromDate, toDate, unlock];
}

class ResetAccStmtEvent extends AccStatementEvent {
  @override
  List<Object?> get props => [];
}