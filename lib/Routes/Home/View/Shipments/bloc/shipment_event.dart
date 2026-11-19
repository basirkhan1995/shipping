
import 'package:equatable/equatable.dart';

abstract class ShipmentEvent extends Equatable {
  const ShipmentEvent();

  @override
  List<Object?> get props => [];
}

// ─────────────────────────────────────────────────────────────
// LOAD
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// CREATE CONTAINER
// ─────────────────────────────────────────────────────────────

class CreateShipment extends ShipmentEvent {
  final String usrName;
  final String portName;
  final String containerNo;
  final String loadingDate;
  final String? sequenceNo;
  final String? unloadingDate;
  final String? description;

  const CreateShipment({
    required this.usrName,
    required this.portName,
    required this.containerNo,
    required this.loadingDate,
    this.sequenceNo,
    this.unloadingDate,
    this.description,
  });

  @override
  List<Object?> get props => [
    usrName,
    portName,
    containerNo,
    loadingDate,
    sequenceNo,
    unloadingDate,
    description,
  ];
}

// ─────────────────────────────────────────────────────────────
// UPDATE CONTAINER
// ─────────────────────────────────────────────────────────────

class UpdateShipment extends ShipmentEvent {
  final String usrName;
  final int shpId;
  final String? portName;
  final String? containerNo;
  final String? sequenceNo;
  final String? loadingDate;
  final String? unloadingDate;
  final String? description;
  final String? status;

  const UpdateShipment({
    required this.usrName,
    required this.shpId,
    this.portName,
    this.containerNo,
    this.sequenceNo,
    this.loadingDate,
    this.unloadingDate,
    this.description,
    this.status,
  });

  @override
  List<Object?> get props => [
    usrName,
    shpId,
    portName,
    containerNo,
    sequenceNo,
    loadingDate,
    unloadingDate,
    description,
    status,
  ];
}

// ─────────────────────────────────────────────────────────────
// DELETE CONTAINER
// ─────────────────────────────────────────────────────────────

class DeleteShipment extends ShipmentEvent {
  final String usrName;
  final int shpId;

  const DeleteShipment({
    required this.usrName,
    required this.shpId,
  });

  @override
  List<Object?> get props => [usrName, shpId];
}
