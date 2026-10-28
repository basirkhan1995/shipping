// lib/features/fund_transfer/bloc/fund_transfer_state.dart
part of 'fund_transfer_bloc.dart';

abstract class FundTransferState extends Equatable {
  const FundTransferState();
  @override
  List<Object?> get props => [];
}

class FundTransferInitial extends FundTransferState {}

/// List loading. Keeps previous rows so the table doesn't flash.
class FundTransferLoading extends FundTransferState {
  final List<FundTransferListItem> previous;
  const FundTransferLoading({this.previous = const []});
  @override
  List<Object?> get props => [previous];
}

/// List loaded.
class FundTransferListLoaded extends FundTransferState {
  final List<FundTransferListItem> rows;

  /// Reference currently being deleted (row-level spinner).
  final String? actionInProgress;

  /// One-shot success banner.
  final String? actionSuccess;

  /// One-shot error banner.
  final String? actionError;

  const FundTransferListLoaded(
      this.rows, {
        this.actionInProgress,
        this.actionSuccess,
        this.actionError,
      });

  FundTransferListLoaded copyWith({
    List<FundTransferListItem>? rows,
    String? actionInProgress,
    String? actionSuccess,
    String? actionError,
    bool clearActionInProgress = false,
    bool clearActionSuccess = false,
    bool clearActionError = false,
  }) {
    return FundTransferListLoaded(
      rows ?? this.rows,
      actionInProgress: clearActionInProgress
          ? null
          : (actionInProgress ?? this.actionInProgress),
      actionSuccess: clearActionSuccess
          ? null
          : (actionSuccess ?? this.actionSuccess),
      actionError:
      clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    rows,
    actionInProgress,
    actionSuccess,
    actionError,
  ];
}

/// Single record loaded (edit form).
class FundTransferDetailLoaded extends FundTransferState {
  final FundTransferDetail detail;
  const FundTransferDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

/// Form submit in progress (add / edit / delete while not on list).
class FundTransferSubmitting extends FundTransferState {
  const FundTransferSubmitting();
}

/// Form submit finished. The UI pops with this and reads `message`.
class FundTransferSubmitSuccess extends FundTransferState {
  final String message;
  final String? reference;
  const FundTransferSubmitSuccess(this.message, {this.reference});
  @override
  List<Object?> get props => [message, reference];
}

/// Error state (list load, detail load, submit, or delete while not
/// in list state).
class FundTransferError extends FundTransferState {
  final String message;
  const FundTransferError(this.message);
  @override
  List<Object?> get props => [message];
}