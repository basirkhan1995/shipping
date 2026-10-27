part of 'transactions_bloc.dart';

sealed class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => const [];
}

final class TransactionsInitial extends TransactionsState {}

final class TransactionsLoadingState extends TransactionsState {
  final List<TransactionListItem> previous;
  const TransactionsLoadingState({this.previous = const []});
  @override
  List<Object?> get props => [previous];
}

final class TransactionsLoadedState extends TransactionsState {
  final List<TransactionListItem> rows;
  final int total;

  /// Which reference is currently being acted on (authorize / unauthorize
  /// / reverse / delete). Null when nothing is in flight.
  /// Row widget: `isBusy = actionInProgress == row.reference`.
  final String? actionInProgress;

  /// Set when a row action fails. Renders as an inline banner.
  /// Cleared by [ClearRowActionErrorEvent] or the next action.
  final String? actionError;

  /// Set on successful row action. The view shows a toast and then
  /// dispatches [ClearRowActionSuccessEvent] to dismiss it.
  final String? actionSuccess;

  const TransactionsLoadedState(
      this.rows, {
        required this.total,
        this.actionInProgress,
        this.actionError,
        this.actionSuccess,
      });

  TransactionsLoadedState copyWith({
    List<TransactionListItem>? rows,
    int? total,
    String? actionInProgress,
    String? actionError,
    String? actionSuccess,
    bool clearActionInProgress = false,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) =>
      TransactionsLoadedState(
        rows ?? this.rows,
        total: total ?? this.total,
        actionInProgress: clearActionInProgress
            ? null
            : (actionInProgress ?? this.actionInProgress),
        actionError: clearActionError
            ? null
            : (actionError ?? this.actionError),
        actionSuccess: clearActionSuccess
            ? null
            : (actionSuccess ?? this.actionSuccess),
      );

  bool get isActionInProgress => actionInProgress != null;

  @override
  List<Object?> get props =>
      [rows, total, actionInProgress, actionError, actionSuccess];
}

final class TransactionsErrorState extends TransactionsState {
  final String message;
  const TransactionsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}