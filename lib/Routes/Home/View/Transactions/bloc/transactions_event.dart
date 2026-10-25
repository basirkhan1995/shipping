part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionsEvent {
  final String? status;             // all | pending | auth | unauth | reversed | deleted
  final String? from;               // YYYY-MM-DD
  final String? to;                 // YYYY-MM-DD
  final String? type;              // 'CHDP' or 'CHDP,CHWL'
  final int? branch;
  final String? search;

  const LoadTransactionsEvent({
     this.status,
     this.from,
     this.to,
    this.type,
    this.branch,
    this.search,
  });

  @override
  List<Object?> get props => [status, from, to, type, branch, search];
}