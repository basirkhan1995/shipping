part of 'transactions_bloc.dart';

sealed class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

final class TransactionsInitial extends TransactionsState {}

final class TransactionsLoadingState extends TransactionsState {
  final List<TransactionRow> previous;
  const TransactionsLoadingState({this.previous = const []});
  @override
  List<Object?> get props => [previous];
}

final class TransactionsLoadedState extends TransactionsState {
  final List<TransactionRow> rows;
  final int total;
  const TransactionsLoadedState(this.rows, {required this.total});
  @override
  List<Object?> get props => [rows, total];
}

final class TransactionsErrorState extends TransactionsState {
  final String message;
  const TransactionsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}