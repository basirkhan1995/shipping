// lib/features/exchange/bloc/exchange_state.dart
part of 'exchange_bloc.dart';

abstract class ExchangeState extends Equatable {
  const ExchangeState();
  @override
  List<Object?> get props => [];
}

class ExchangeInitial extends ExchangeState {}

class ExchangeLoading extends ExchangeState {
  final List<ExchangeListItem> previous;
  const ExchangeLoading({this.previous = const []});
  @override
  List<Object?> get props => [previous];
}

class ExchangeListLoaded extends ExchangeState {
  final List<ExchangeListItem> rows;

  /// Reference of the row currently being mutated (delete spinner).
  final String? actionInProgress;

  /// One-shot success banner.
  final String? actionSuccess;

  /// One-shot error banner.
  final String? actionError;

  const ExchangeListLoaded(
      this.rows, {
        this.actionInProgress,
        this.actionSuccess,
        this.actionError,
      });

  ExchangeListLoaded copyWith({
    List<ExchangeListItem>? rows,
    String? actionInProgress,
    String? actionSuccess,
    String? actionError,
    bool clearActionInProgress = false,
    bool clearActionSuccess = false,
    bool clearActionError = false,
  }) {
    return ExchangeListLoaded(
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
  List<Object?> get props =>
      [rows, actionInProgress, actionSuccess, actionError];
}

class ExchangeDetailLoaded extends ExchangeState {
  final ExchangeDetail detail;
  const ExchangeDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

class ExchangeSubmitting extends ExchangeState {
  const ExchangeSubmitting();
}

class ExchangeSubmitSuccess extends ExchangeState {
  final String message;
  final String? reference;
  const ExchangeSubmitSuccess(this.message, {this.reference});
  @override
  List<Object?> get props => [message, reference];
}

class ExchangeError extends ExchangeState {
  final String message;
  const ExchangeError(this.message);
  @override
  List<Object?> get props => [message];
}