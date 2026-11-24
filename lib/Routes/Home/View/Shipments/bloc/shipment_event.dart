import 'package:equatable/equatable.dart';

abstract class ShipmentEvent extends Equatable {
  const ShipmentEvent();

  @override
  List<Object?> get props => [];
}

// ─────────────────────────────────────────────────────────────
// LOAD / REFRESH
// ─────────────────────────────────────────────────────────────

class LoadShipments extends ShipmentEvent {
  final String status;
  final String? search;
  final String? containerNo;
  final String? sequenceNo;
  final String? from;
  final String? to;

  const LoadShipments({
    this.status = 'pending',
    this.search,
    this.containerNo,
    this.sequenceNo,
    this.from,
    this.to,
  });

  @override
  List<Object?> get props => [
    status,
    search,
    containerNo,
    sequenceNo,
    from,
    to,
  ];
}

class RefreshShipments extends ShipmentEvent {
  const RefreshShipments();
}

// ─────────────────────────────────────────────────────────────
// CREATE
// ─────────────────────────────────────────────────────────────

class CreateShipment extends ShipmentEvent {
  final String usrName;
  final String portName;
  final String containerNo;
  final String loadingDate;
  final String? sequenceNo;
  final String? unloadingDate;
  final String? description;
  final String status;

  const CreateShipment({
    required this.usrName,
    required this.portName,
    required this.containerNo,
    required this.loadingDate,
    this.sequenceNo,
    this.unloadingDate,
    this.description,
    this.status = 'pending',
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
    status,
  ];
}

// ─────────────────────────────────────────────────────────────
// UPDATE
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
// DELETE
// ─────────────────────────────────────────────────────────────

class DeleteShipment extends ShipmentEvent {
  final String usrName;
  final int shpId;
  final bool force;

  const DeleteShipment({
    required this.usrName,
    required this.shpId,
    this.force = false,
  });

  @override
  List<Object?> get props => [usrName, shpId, force];
}

// ─────────────────────────────────────────────────────────────
// RESOLVE INPUT → open container
// ─────────────────────────────────────────────────────────────

class ResolveShipmentByInput extends ShipmentEvent {
  final String input;

  const ResolveShipmentByInput(this.input);

  @override
  List<Object?> get props => [input];
}