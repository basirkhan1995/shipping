
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
  final int page;
  final int size;
  final String statusFilter;
  final bool hasMore;
  final bool isLoadingMore;

  const ShipmentLoaded({
    required this.shipments,
    required this.page,
    required this.size,
    required this.statusFilter,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  ShipmentLoaded copyWith({
    List<ShipmentModel>? shipments,
    int? page,
    int? size,
    String? statusFilter,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ShipmentLoaded(
      shipments: shipments ?? this.shipments,
      page: page ?? this.page,
      size: size ?? this.size,
      statusFilter: statusFilter ?? this.statusFilter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    shipments,
    page,
    size,
    statusFilter,
    hasMore,
    isLoadingMore,
  ];
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
