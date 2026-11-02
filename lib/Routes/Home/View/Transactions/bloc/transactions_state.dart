part of 'transactions_bloc.dart';

sealed class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => const [];
}

final class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

final class TransactionsLoadingState extends TransactionsState {
  final List<TransactionListItem> previous;
  const TransactionsLoadingState({this.previous = const []});
  @override
  List<Object?> get props => [previous];
}

/// Identifies *which* row action is currently running, in addition to
/// [TransactionsLoadedState.actionInProgress] (which row it's running on).
///
/// The dialog ignores this — it only ever renders one action button per
/// state, so `actionInProgress == reference` is enough there. The list
/// uses it to spin only the tapped icon when a row has multiple actions.
enum RowAction { authorize, unauthorize, reverse, delete }

final class TransactionsLoadedState extends TransactionsState {
  final List<TransactionListItem> rows;
  final int total;

  /// Which reference is currently being acted on. Null when nothing is
  /// in flight. Row widget: `isBusy = actionInProgress == row.reference`.
  final String? actionInProgress;

  /// Which action is running on that row. Only meaningful when
  /// [actionInProgress] is non-null. Cleared together with it.
  final RowAction? actionKind;

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
        this.actionKind,
        this.actionError,
        this.actionSuccess,
      });

  TransactionsLoadedState copyWith({
    List<TransactionListItem>? rows,
    int? total,
    String? actionInProgress,
    RowAction? actionKind,
    String? actionError,
    String? actionSuccess,
    bool clearActionInProgress = false,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) =>
      TransactionsLoadedState(
        rows ?? this.rows,
        total: total ?? this.total,
        // These two MUST clear together — a stale kind with no reference
        // would make the next busy row spin the wrong icon.
        actionInProgress: clearActionInProgress
            ? null
            : (actionInProgress ?? this.actionInProgress),
        actionKind: clearActionInProgress
            ? null
            : (actionKind ?? this.actionKind),
        actionError: clearActionError ? null : (actionError ?? this.actionError),
        actionSuccess:
        clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
      );

  bool get isActionInProgress => actionInProgress != null;

  @override
  List<Object?> get props =>
      [rows, total, actionInProgress, actionKind, actionError, actionSuccess];
}

final class TransactionsErrorState extends TransactionsState {
  final String message;
  const TransactionsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}