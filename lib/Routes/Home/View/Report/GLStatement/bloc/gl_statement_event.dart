part of 'gl_statement_bloc.dart';

sealed class GlStatementEvent extends Equatable {
  const GlStatementEvent();
}

class LoadGlStatementEvent extends GlStatementEvent{
  final int accountNumber;
  final int branchCode;
  final String currency;
  final String fromDate;
  final String toDate;
  const LoadGlStatementEvent({required this.branchCode, required this.currency, required this.accountNumber, required this.fromDate, required this.toDate});

  @override
  List<Object?> get props => [branchCode, currency, accountNumber, fromDate, toDate];
}

class ResetGlStmtEvent extends GlStatementEvent{
  @override

  List<Object?> get props => [];
}