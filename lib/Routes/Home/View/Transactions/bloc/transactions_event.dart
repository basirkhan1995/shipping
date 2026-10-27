part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => const [];
}

class LoadTransactionsEvent extends TransactionsEvent {
  final String? status;
  final String? from;
  final String? to;
  final String? type;
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

// ── Row actions ──────────────────────────────────────────────────

class AuthorizeTransactionEvent extends TransactionsEvent {
  final String reference;
  final String? userName;
  const AuthorizeTransactionEvent({
    required this.reference,
    required this.userName,
  });
  @override
  List<Object?> get props => [reference, userName];
}

class UnauthorizeTransactionEvent extends TransactionsEvent {
  final String reference;
  final String? userName;
  const UnauthorizeTransactionEvent({
    required this.reference,
    required this.userName,
  });
  @override
  List<Object?> get props => [reference, userName];
}

class ReverseTransactionEvent extends TransactionsEvent {
  final String reference;
  final String? userName;
  const ReverseTransactionEvent({
    required this.reference,
    required this.userName,
  });
  @override
  List<Object?> get props => [reference, userName];
}

class DeleteTransactionEvent extends TransactionsEvent {
  final String reference;
  final String? userName;
  const DeleteTransactionEvent({
    required this.reference,
    required this.userName,
  });
  @override
  List<Object?> get props => [reference, userName];
}

class ClearRowActionErrorEvent extends TransactionsEvent {
  const ClearRowActionErrorEvent();
}

class ClearRowActionSuccessEvent extends TransactionsEvent {
  const ClearRowActionSuccessEvent();
}