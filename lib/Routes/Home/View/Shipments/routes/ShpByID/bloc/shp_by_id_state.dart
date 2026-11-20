part of 'shp_by_id_bloc.dart';

sealed class ShpByIdState extends Equatable {
  const ShpByIdState();

  @override
  List<Object?> get props => [];
}

/// Initial / idle.
final class ShpByIdInitial extends ShpByIdState {}

/// Loading (initial load, refresh, or after an action re-fetch).
final class ShpByIdLoading extends ShpByIdState {
  /// Kept so the UI doesn't flash while refreshing.
  final ShipmentDetailsModel? previous;

  /// True when this loading is the re-fetch that follows a mutation
  /// (so we don't show a full-screen spinner on the whole screen).
  final bool fromAction;

  const ShpByIdLoading({this.previous, this.fromAction = false});

  @override
  List<Object?> get props => [previous, fromAction];
}

/// Successfully loaded shipment + items.
final class ShpByIdLoaded extends ShpByIdState {
  final ShipmentDetailsModel details;

  /// The in-flight mutation (add/update/delete). Null when idle.
  final ShpByIdAction? pendingAction;

  /// One-shot success message (consumed by the view).
  final String? successMessage;

  /// One-shot error from a mutation (consumed by the view).
  final String? actionError;

  const ShpByIdLoaded(
      this.details, {
        this.pendingAction,
        this.successMessage,
        this.actionError,
      });

  bool get isMutating => pendingAction != null;

  ShpByIdLoaded copyWith({
    ShipmentDetailsModel? details,
    ShpByIdAction? pendingAction,
    bool clearPendingAction = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return ShpByIdLoaded(
      details ?? this.details,
      pendingAction:
      clearPendingAction ? null : (pendingAction ?? this.pendingAction),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props =>
      [details, pendingAction, successMessage, actionError];
}

/// Something went wrong while loading the screen.
final class ShpByIdError extends ShpByIdState {
  final String message;
  final int? statusCode;

  const ShpByIdError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Which mutation is currently in-flight.
enum ShpByIdAction { addItem, updateItem, deleteItem, updateItemStatus}