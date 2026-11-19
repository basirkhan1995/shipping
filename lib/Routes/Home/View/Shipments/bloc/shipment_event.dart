import 'package:equatable/equatable.dart';

abstract class ShipmentEvent extends Equatable {
  const ShipmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadShipments extends ShipmentEvent {
  final String status;
  final String? search;
  final String? shpReference;
  final String? containerNo;
  final String? sequenceNo;
  final String? from;
  final String? to;

  const LoadShipments({
    this.status = 'pending',
    this.search,
    this.shpReference,
    this.containerNo,
    this.sequenceNo,
    this.from,
    this.to,
  });

  @override
  List<Object?> get props => [
    status,
    search,
    shpReference,
    containerNo,
    sequenceNo,
    from,
    to,
  ];
}

class LoadMoreShipments extends ShipmentEvent {
  const LoadMoreShipments();
}

class RefreshShipments extends ShipmentEvent {
  const RefreshShipments();
}