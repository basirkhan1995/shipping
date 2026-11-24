import 'package:equatable/equatable.dart';
import '../model/shp_model.dart';

abstract class ShipmentState extends Equatable {
  const ShipmentState();

  @override
  List<Object?> get props => [];
}

class ShipmentInitial extends ShipmentState {
  const ShipmentInitial();
}

class ShipmentLoading extends ShipmentState {
  const ShipmentLoading();
}

class ShipmentLoaded extends ShipmentState {
  final List<ShipmentModel> shipments;
  final String statusFilter;

  const ShipmentLoaded({
    required this.shipments,
    required this.statusFilter,
  });

  @override
  List<Object?> get props => [shipments, statusFilter];
}

class ShipmentError extends ShipmentState {
  final String message;

  const ShipmentError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────
// CONTAINER OPERATIONS
// ─────────────────────────────────────────────────────────────

class ShipmentOperationLoading extends ShipmentState {
  final String operation;

  const ShipmentOperationLoading(this.operation);

  @override
  List<Object?> get props => [operation];
}

class ShipmentOperationSuccess extends ShipmentState {
  final String message;
  final int? shpId;

  const ShipmentOperationSuccess({
    required this.message,
    this.shpId,
  });

  @override
  List<Object?> get props => [message, shpId];
}

class ShipmentOperationError extends ShipmentState {
  final String message;

  const ShipmentOperationError(this.message);

  @override
  List<Object?> get props => [message];
}

class ShipmentResolved extends ShipmentState {
  final int shpId;

  const ShipmentResolved(this.shpId);

  @override
  List<Object?> get props => [shpId];
}

class ShipmentResolveNotFound extends ShipmentState {
  final String input;

  const ShipmentResolveNotFound(this.input);

  @override
  List<Object?> get props => [input];
}